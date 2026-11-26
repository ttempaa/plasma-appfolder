import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

import "code/Placement.js" as Placement
import "code/SharedConf.js" as SharedConf
import "code/Paths.js" as Paths
import "code/Shell.js" as Shell
import "code/DesktopFile.js" as DesktopFile

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // the label may be wider than the icon (up to 1.75x), so long names
    // wrap naturally instead of breaking mid-word
    implicitWidth: Math.max(root.cellSize, Math.min(Math.ceil(labelOneLine.implicitWidth) + 2, Math.round(root.cellSize * 1.75)))
    implicitHeight: root.cellSize + Math.ceil(labelMetrics.height * 2) + Kirigami.Units.smallSpacing

    Layout.minimumWidth: root.implicitWidth
    Layout.minimumHeight: root.implicitHeight

    readonly property url folderUrl: {
        const raw = Plasmoid.configuration.folder || "";
        if (!raw) {
            return "";
        }
        return raw.startsWith("file://") ? raw : "file://" + raw;
    }

    readonly property string folderName: {
        if (Plasmoid.configuration.labelText) {
            return Plasmoid.configuration.labelText;
        }
        const raw = Plasmoid.configuration.folder || "";
        if (!raw) {
            return i18n("Not configured");
        }
        return Paths.percentDecode(Paths.basename(raw));
    }

    property var apps: []
    // plain property updated by syncVisibleApps(), deliberately not a binding:
    // name/isApplication inside AppInfo arrive asynchronously, and a var array would
    // not propagate those deep changes to anything bound to it
    property var visibleApps: []

    function rebuild() {
        const byUrl = {};
        for (let i = 0; i < apps.length; ++i) {
            byUrl[apps[i].source.toString()] = apps[i];
        }
        const fresh = [];
        for (let i = 0; i < folderModel.count; ++i) {
            const url = folderModel.get(i, "fileUrl").toString();
            const info = byUrl[url] || appInfoComponent.createObject(root, { source: url });
            delete byUrl[url];
            fresh.push(info);
            requestText(info);
        }
        apps = fresh;
        const gone = Object.keys(byUrl);
        for (let i = 0; i < gone.length; ++i) {
            byUrl[gone[i]].dead = true;
            byUrl[gone[i]].destroy();
        }
        syncVisibleApps();
    }

    function syncVisibleApps() {
        visibleAppsTimer.restart();
    }

    // the model reports a folder change as a burst of count updates; one
    // rebuild per burst instead of one per file
    Timer {
        id: rebuildTimer

        interval: 50
        onTriggered: root.rebuild()
    }

    Timer {
        id: visibleAppsTimer

        interval: 50
        onTriggered: {
            const sortMode = Plasmoid.configuration.sortMode || "name";
            root.visibleApps = DesktopFile.visibleApps(root.apps, sortMode);
        }
    }

    // .desktop reads are batched: every file of the folder is
    // dumped by one cat process — QML itself cannot read local files (the
    // XHR file scheme needs QML_XHR_ALLOW_FILE_READ), the executable engine
    // has no such restriction
    property var pendingInfos: []
    property var batchByCmd: ({})

    function requestText(info) {
        pendingInfos.push(info);
        batchTimer.restart();
    }

    Timer {
        id: batchTimer

        interval: 50
        onTriggered: root.runBatch()
    }

    function runBatch() {
        if (pendingInfos.length === 0) {
            return;
        }
        const byPath = {};
        for (let i = 0; i < pendingInfos.length; ++i) {
            const info = pendingInfos[i];
            if (!info.dead) {
                byPath[Paths.urlToPath(info.source.toString())] = info;
            }
        }
        pendingInfos = [];
        const paths = Object.keys(byPath);
        if (paths.length === 0) {
            return;
        }
        const cmd = DesktopFile.catCmd(paths);
        // identical commands merge: the engine keys responses by command
        if (batchByCmd[cmd]) {
            Object.assign(batchByCmd[cmd], byPath);
            return;
        }
        batchByCmd[cmd] = byPath;
        fileExec.connectSource(cmd);
    }

    Plasma5Support.DataSource {
        id: fileExec

        engine: "executable"
        onNewData: (sourceName, data) => {
            fileExec.disconnectSource(sourceName);
            const byPath = batchByCmd[sourceName];
            delete batchByCmd[sourceName];
            if (!byPath) {
                return;
            }
            const records = DesktopFile.parseCat((data["stdout"] ?? "") + "");
            for (const path in byPath) {
                const info = byPath[path];
                if (info.dead) {
                    continue;
                }
                const text = records[path];
                if (text === undefined || text === "") {
                    info.applyFileName();
                } else {
                    info.applyText(text);
                }
            }
        }
    }

    // sorting is not a binding input: recompute the visible list when it changes
    Connections {
        target: Plasmoid.configuration
        function onValueChanged(key) {
            if (key === "sortMode") {
                root.syncVisibleApps();
            }
        }
    }

    FolderListModel {
        id: folderModel

        folder: root.folderUrl
        showDirs: false
        showHidden: false
        showOnlyReadable: true
        nameFilters: ["*.desktop"]
        sortField: FolderListModel.Name

        onFolderChanged: rebuildTimer.restart()
        onCountChanged: rebuildTimer.restart()
        onDataChanged: rebuildTimer.restart()
    }

    Component {
        id: appInfoComponent

        AppInfo {
            onNameChanged: root.syncVisibleApps()
            onIsApplicationChanged: root.syncVisibleApps()
        }
    }

    readonly property int gridCols: {
        const mode = Plasmoid.configuration.gridMode || "auto";
        if (mode === "auto") {
            // smallest square that fits everything, bounded by the user's max
            const max = Math.min(4, Math.max(2, Plasmoid.configuration.gridMax || 3));
            let cols = 2;
            while (cols < max && visibleApps.length > cols * cols) {
                ++cols;
            }
            return cols;
        }
        return Math.min(4, Math.max(2, parseInt(mode) || 2));
    }
    readonly property int compositeCount: Math.min(visibleApps.length, gridCols * gridCols)
    readonly property bool showFrame: Plasmoid.configuration.showFrame !== false
    readonly property int cellSize: Plasmoid.configuration.iconSize > 0 ? Plasmoid.configuration.iconSize : 64

    // screen margins are shared by every instance, not per-widget settings
    QtObject {
        id: sharedConfig

        property int marginTop: 0
        property int marginRight: 0
        property int marginBottom: 0
        property int marginLeft: 0

        property bool reading: false

        function refresh() {
            // async engine read settles long before the first popup opens
            if (reading) {
                return;
            }
            reading = true;
            configExec.connectSource(SharedConf.readAllCmd());
        }

        function applyConfig(stdout) {
            reading = false;
            const vals = SharedConf.parseAll(stdout);
            if (vals) {
                applyShared(vals);
            }
        }

        function applyShared(vals) {
            marginTop = vals.marginTop;
            marginRight = vals.marginRight;
            marginBottom = vals.marginBottom;
            marginLeft = vals.marginLeft;
            sharedDefaultsConfigured = vals.defaultsConfigured;
            applyDefaultsOnce(vals);
            // strictly after the shared defaults settled, so an explicit
            // shared value always wins over the desktop-size detection
            ensureManagedFolder();
        }

        // one-time per instance: a widget that was never touched (every key
        // still at its schema default) picks up the shared defaults for
        // new widgets; anything the user configured wins
        function applyDefaultsOnce(vals) {
            if (Plasmoid.configuration.defaultsApplied) {
                return;
            }
            Plasmoid.configuration.defaultsApplied = true;
            // [key, schema default] pairs from main.xml; untouched means
            // the value still falls back to the default or equals it — an
            // explicit 0 int or an inverted bool counts as user-configured
            const defs = [
                ["folder", ""],
                ["labelText", ""],
                ["iconSize", 64],
                ["gridMode", "auto"],
                ["gridMax", 3],
                ["sortMode", "name"],
                ["showFrame", true],
                ["openOnHover", false],
                ["popupPlacement", "auto"],
                ["autoPreference", "up"],
                ["autoBias", 12]
            ];
            let untouched = true;
            for (let i = 0; i < defs.length; ++i) {
                const key = defs[i][0];
                const def = defs[i][1];
                const v = Plasmoid.configuration[key];
                if (typeof def === "boolean") {
                    untouched = v !== !def;
                } else if (typeof def === "number") {
                    untouched = (v || 0) === def;
                } else {
                    untouched = (v || def) === def;
                }
                if (!untouched) {
                    break;
                }
            }
            if (!untouched || !vals.hasDefaults) {
                return;
            }
            if (vals.defaults.iconSize !== null) {
                Plasmoid.configuration.iconSize = vals.defaults.iconSize;
            }
            if (vals.defaults.gridMode !== null) {
                Plasmoid.configuration.gridMode = vals.defaults.gridMode;
            }
            if (vals.defaults.gridMax !== null) {
                Plasmoid.configuration.gridMax = vals.defaults.gridMax;
            }
            if (vals.defaults.sortMode !== null) {
                Plasmoid.configuration.sortMode = vals.defaults.sortMode;
            }
            if (vals.defaults.showFrame !== null) {
                Plasmoid.configuration.showFrame = vals.defaults.showFrame;
            }
            if (vals.defaults.openOnHover !== null) {
                Plasmoid.configuration.openOnHover = vals.defaults.openOnHover;
            }
        }
    }

    // the desktop-size detection may size a fresh widget only until the user has saved shared defaults at least once
    property bool sharedDefaultsConfigured: false

    Plasma5Support.DataSource {
        id: configExec

        engine: "executable"
        onNewData: (sourceName, data) => {
            configExec.disconnectSource(sourceName);
            sharedConfig.applyConfig(((data["stdout"] ?? "") + ""));
        }
    }


    Component.onCompleted: sharedConfig.refresh()

    readonly property var screenMargins: ({
        top: sharedConfig.marginTop,
        right: sharedConfig.marginRight,
        bottom: sharedConfig.marginBottom,
        left: sharedConfig.marginLeft
    })

    FontMetrics {
        id: labelMetrics

        font: label.font
    }

    TextMetrics {
        id: labelOneLine

        font: label.font
        text: root.folderName
    }

    Column {
        id: body

        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        CompositeIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            cellPx: root.cellSize
            cols: root.gridCols
            count: root.visibleApps.length
            showFrame: root.showFrame
            icons: root.visibleApps.map(info => info.icon)
        }

        PlasmaExtras.ShadowedLabel {
            id: label

            width: root.width
            renderShadow: true
            color: "white"
            text: root.folderName
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }
    }

    Plasma5Support.DataSource {
        id: actionExec

        engine: "executable"

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
    }

    // launchers dropped onto the widget move into its folder;
    // the folder model picks the change up on its own
    DropArea {
        id: dropArea

        anchors.fill: parent
        enabled: root.folderUrl.toString() !== ""
        keys: ["text/uri-list"]

        onDropped: (drop) => {
            const cmd = DesktopFile.dropCmd(drop.urls, root.folderUrl.toString());
            if (cmd !== "") {
                actionExec.connectSource(cmd);
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.largeSpacing
            color: Qt.alpha(Kirigami.Theme.highlightColor, 0.18)
            border.width: 2
            border.color: Kirigami.Theme.highlightColor
            visible: dropArea.containsDrag
        }
    }

    function launch(info) {
        if (!info || info.source.toString() === "") {
            return;
        }
        actionExec.connectSource("kioclient exec " + Shell.quote(info.source.toString()));
        popup.visible = false;
    }

    function openFolder() {
        const url = root.folderUrl.toString();
        if (url === "") {
            return;
        }
        actionExec.connectSource("kioclient exec " + Shell.quote(url));
    }

    Plasma5Support.DataSource {
        id: managedFolderExec

        engine: "executable"

        // the desktop folder containment stores its icon size as an index
        // into this ladder (same Kirigami units as the containment itself)
        readonly property var iconSizeLadder: [
            Kirigami.Units.iconSizes.smallMedium,
            Kirigami.Units.iconSizes.medium,
            Kirigami.Units.iconSizes.large,
            Kirigami.Units.iconSizes.huge,
            Kirigami.Units.iconSizes.large * 2,
            Kirigami.Units.iconSizes.enormous
        ]

        onNewData: (sourceName, data) => {
            managedFolderExec.disconnectSource(sourceName);
            const lines = (((data["stdout"] ?? "") + "").trim()).split("\n");
            const path = (lines[0] || "").trim();
            // mkdir may lose a race for the folder name; its && then skips
            // the path line and the icon-size index lands first
            if (path.startsWith("/") && (Plasmoid.configuration.folder || "") === "") {
                Plasmoid.configuration.folder = path;
                if (!Plasmoid.configuration.labelText) {
                    // the on-disk folder name is latin; the label is localized
                    Plasmoid.configuration.labelText = i18n("Applications");
                }
                const idx = parseInt((lines[1] || "").trim(), 10);
                const size = isNaN(idx) ? 0 : (iconSizeLadder[idx] ?? 0);
                if (size >= 16 && Plasmoid.configuration.iconSize === 64
                        && !root.sharedDefaultsConfigured) {
                    // size a fresh widget like the desktop icons
                    Plasmoid.configuration.iconSize = size;
                }
            }
        }
    }

    // a fresh widget gets its own folder under the shared data dir right away, so launchers can be dropped onto it immediately
    function ensureManagedFolder() {
        if ((Plasmoid.configuration.folder || "") !== "") {
            return;
        }
        managedFolderExec.connectSource(SharedConf.managedFolderCmd());
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Open Folder")
            icon.name: "folder-open"
            visible: root.folderUrl.toString() !== ""
            onTriggered: root.openFolder()
        }
    ]

    function autoSide() {
        const win = root.Window.window;
        if (!win) {
            return "up";
        }
        const p = root.mapToItem(win.contentItem, 0, 0);
        const needH = popup.contentImplicitHeight;
        const needW = popup.contentImplicitWidth;
        const margins = root.screenMargins;
        const waW = Math.max(1, win.width - margins.left - margins.right);
        const waH = Math.max(1, win.height - margins.top - margins.bottom);

        const dUp = p.y - margins.top;
        const dDown = (margins.top + waH) - (p.y + root.height);
        const dLeft = p.x - margins.left;
        const dRight = (margins.left + waW) - (p.x + root.width);

        const fitsSide = side => {
            if (side === "up") {
                return dUp >= needH;
            }
            if (side === "down") {
                return dDown >= needH;
            }
            if (side === "left") {
                return dLeft >= needW;
            }
            return dRight >= needW;
        };

        // free space as work-area fractions, so a wide screen does not give
        // the horizontal sides an unfair advantage
        const freeUp = dUp / waH;
        const freeDown = dDown / waH;
        const freeLeft = dLeft / waW;
        const freeRight = dRight / waW;

        const prefSide = Plasmoid.configuration.autoPreference || "up";
        const tolerance = Math.max(0, Plasmoid.configuration.autoBias || 0) / 100;
        let side = Placement.pickSide(freeUp, freeDown, freeLeft, freeRight, prefSide, tolerance);

        const opposite = { up: "down", down: "up", left: "right", right: "left" };
        if (!fitsSide(side) && fitsSide(opposite[side])) {
            side = opposite[side];
        }

        const spaces = [
            ["up", dUp],
            ["down", dDown],
            ["left", dLeft],
            ["right", dRight]
        ];
        spaces.sort((a, b) => b[1] - a[1]);
        return fitsSide(side) ? side : spaces[0][0];
    }

    function placePopup() {
        const win = root.Window.window;
        if (!win) {
            return;
        }
        const mode = Plasmoid.configuration.popupPlacement || "auto";
        const side = mode === "auto" ? root.autoSide() : mode;

        const gap = Kirigami.Units.largeSpacing;
        const pw = popup.width > 0 ? popup.width : popup.contentImplicitWidth;
        const ph = popup.height > 0 ? popup.height : popup.contentImplicitHeight;
        const p = root.mapToItem(win.contentItem, 0, 0);

        const pos = Placement.popupPosition(side,
            { x: p.x, y: p.y, width: root.width, height: root.height },
            { width: pw, height: ph },
            root.screenMargins,
            gap,
            { width: win.width, height: win.height });

        popup.location = ({
            up: PlasmaCore.Types.BottomEdge,
            down: PlasmaCore.Types.TopEdge,
            left: PlasmaCore.Types.RightEdge,
            right: PlasmaCore.Types.LeftEdge
        })[side];
        popup.x = pos.x;
        popup.y = pos.y;
    }

    function openPopup() {
        rebuild();
        sharedConfig.refresh();
        placePopup();
        popup.visible = true;
    }

    AppFolderPopup {
        id: popup

        apps: root.visibleApps
        cellPx: root.cellSize + Kirigami.Units.gridUnit * 2
        cols: root.gridCols
        maxVisibleRows: 5

        onLaunched: info => root.launch(info)
        onHovered: hovered => hovered ? popupCloseTimer.stop() : popupCloseTimer.restart()

        // reposition when the size settles: the first show lays the content out late
        onWidthChanged: if (visible) root.placePopup()
        onHeightChanged: if (visible) root.placePopup()
    }

    Timer {
        id: popupCloseTimer

        interval: 500
        onTriggered: popup.visible = false
    }

    TapHandler {
        onTapped: {
            popupCloseTimer.stop();
            if (popup.visible) {
                popup.visible = false;
            } else {
                root.openPopup();
            }
        }
    }

    HoverHandler {
        id: widgetHover

        onHoveredChanged: {
            if (!Plasmoid.configuration.openOnHover) {
                return;
            }
            if (hovered) {
                popupCloseTimer.stop();
                root.openPopup();
            } else {
                popupCloseTimer.restart();
            }
        }
    }
}
