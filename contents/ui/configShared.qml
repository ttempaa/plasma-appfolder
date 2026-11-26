import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import QtCore

import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

import "code/SharedConf.js" as SharedConf

Item {
    id: configShared

    // the shell config window maps Return to OK; swallow it so typing never closes the dialog
    Keys.onReturnPressed: event => event.accepted = true
    Keys.onEnterPressed: event => event.accepted = true

    // not cfg_ properties: shared by every instance, applied immediately
    property int marginTop: 0
    property int marginRight: 0
    property int marginBottom: 0
    property int marginLeft: 0

    // defaults applied to newly added widgets
    property int defaultIconSize: 64
    property string defaultGridMode: "auto"
    property int defaultGridMax: 3
    property string defaultSortMode: "name"
    property bool defaultShowFrame: true
    property bool defaultOpenOnHover: false

    readonly property int screenWidth: Screen.width || 1920
    readonly property int screenHeight: Screen.height || 1080

    // read synchronously at page creation: an async engine read would flash the defaults
    readonly property url configUrl: StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
        + "/" + SharedConf.DATA_DIR + "/" + SharedConf.FILE

    // QtCore, not Qt.labs: labs lost its source property in Qt 6.12
    Settings {
        id: generalSnapshot

        location: configShared.configUrl
    }

    // General maps to the empty category: "General" would read [%General],
    // which kwriteconfig6 never writes
    Settings {
        id: defaultsSnapshot

        location: configShared.configUrl
        category: SharedConf.DEFAULTS_GROUP
    }

    Component.onCompleted: {
        // value() returns raw INI strings; absent keys fall back to the page defaults
        marginTop = Number(generalSnapshot.value("marginTop", marginTop));
        marginRight = Number(generalSnapshot.value("marginRight", marginRight));
        marginBottom = Number(generalSnapshot.value("marginBottom", marginBottom));
        marginLeft = Number(generalSnapshot.value("marginLeft", marginLeft));
        defaultIconSize = Number(defaultsSnapshot.value("iconSize", defaultIconSize));
        defaultGridMode = defaultsSnapshot.value("gridMode", defaultGridMode) + "";
        defaultGridMax = Number(defaultsSnapshot.value("gridMax", defaultGridMax));
        defaultSortMode = defaultsSnapshot.value("sortMode", defaultSortMode) + "";
        defaultShowFrame = toBool(defaultsSnapshot.value("showFrame", defaultShowFrame));
        defaultOpenOnHover = toBool(defaultsSnapshot.value("openOnHover", defaultOpenOnHover));
    }

    // INI booleans arrive as "true"/"false" strings
    function toBool(v) {
        if (v === true || v === "true") {
            return true;
        }
        if (v === false || v === "false") {
            return false;
        }
        return v;
    }

    Plasma5Support.DataSource {
        id: writeExec

        engine: "executable"
        onNewData: (sourceName, data) => writeExec.disconnectSource(sourceName)
    }

    function writeAll() {
        const margins = {
            marginTop: marginTop,
            marginRight: marginRight,
            marginBottom: marginBottom,
            marginLeft: marginLeft
        };
        const defaults = {
            iconSize: defaultIconSize,
            gridMode: defaultGridMode,
            gridMax: defaultGridMax,
            sortMode: defaultSortMode,
            showFrame: defaultShowFrame,
            openOnHover: defaultOpenOnHover
        };
        writeExec.connectSource(SharedConf.writeMarginsCmd(margins)
            + "; " + SharedConf.writeDefaultsCmd(defaults));
    }

    // coalesce spinbox edits into one burst of writes
    Timer {
        id: writeTimer

        interval: 400
        onTriggered: configShared.writeAll()
    }

    // flush a pending debounce on close, or quick edits die with the page
    Component.onDestruction: {
        if (writeTimer.active) {
            writeAll();
        }
    }

    function scheduleWrite() {
        writeTimer.restart();
    }

    function syncSizeBox() {
        for (let i = 0; i < defaultSizeBox.count; ++i) {
            if (defaultSizeBox.model[i].value === defaultIconSize) {
                defaultSizeBox.currentIndex = i;
                break;
            }
        }
    }

    function syncGridBox() {
        for (let i = 0; i < defaultGridBox.count; ++i) {
            if (defaultGridBox.model[i].value === defaultGridMode) {
                defaultGridBox.currentIndex = i;
                break;
            }
        }
    }

    function syncMaxGridBox() {
        for (let i = 0; i < defaultGridMaxBox.count; ++i) {
            if (defaultGridMaxBox.model[i].value === defaultGridMax) {
                defaultGridMaxBox.currentIndex = i;
                break;
            }
        }
    }

    function syncSortBox() {
        for (let i = 0; i < defaultSortBox.count; ++i) {
            if (defaultSortBox.model[i].value === defaultSortMode) {
                defaultSortBox.currentIndex = i;
                break;
            }
        }
    }

    // one sync pattern for every control: property changes push into the
    // controls from here, user input writes back through onValueModified/
    // onActivated handlers — equal assignments emit no signal, so no loops
    onMarginTopChanged: topSpin.value = marginTop
    onMarginRightChanged: rightSpin.value = marginRight
    onMarginBottomChanged: bottomSpin.value = marginBottom
    onMarginLeftChanged: leftSpin.value = marginLeft
    onDefaultIconSizeChanged: syncSizeBox()
    onDefaultGridModeChanged: syncGridBox()
    onDefaultGridMaxChanged: syncMaxGridBox()
    onDefaultSortModeChanged: syncSortBox()
    onDefaultOpenOnHoverChanged: defaultOpenOnHoverBox.currentIndex = defaultOpenOnHover ? 1 : 0

    function openMarginEditor() {
        marginEditor.screenMargins = {
            top: marginTop,
            right: marginRight,
            bottom: marginBottom,
            left: marginLeft
        };
        marginEditor.open(screenWidth, screenHeight);
    }

    QQC2.ScrollView {
        id: pageScroll

        anchors.fill: parent

        ColumnLayout {
            width: pageScroll.availableWidth
            spacing: 0

            Kirigami.FormLayout {
                Layout.fillWidth: true

                SectionHeader {
                    title: i18n("Screen margins")
                    first: true
                    note: i18n("Shared by all app folder widgets; applied immediately.")
                }

                QQC2.SpinBox {
                    id: topSpin

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Top:")
                    implicitWidth: 86
                    from: 0
                    to: SharedConf.MAX_MARGIN
                    stepSize: 1
                    editable: true
                    Component.onCompleted: value = marginTop
                    onValueModified: {
                        marginTop = value;
                        scheduleWrite();
                    }
                    QQC2.ToolTip.text: i18n("Forbidden zone the popup never enters, for example behind the taskbar.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.SpinBox {
                    id: rightSpin

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Right:")
                    implicitWidth: 86
                    from: 0
                    to: SharedConf.MAX_MARGIN
                    stepSize: 1
                    editable: true
                    Component.onCompleted: value = marginRight
                    onValueModified: {
                        marginRight = value;
                        scheduleWrite();
                    }
                    QQC2.ToolTip.text: i18n("Forbidden zone the popup never enters.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.SpinBox {
                    id: bottomSpin

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Bottom:")
                    implicitWidth: 86
                    from: 0
                    to: SharedConf.MAX_MARGIN
                    stepSize: 1
                    editable: true
                    Component.onCompleted: value = marginBottom
                    onValueModified: {
                        marginBottom = value;
                        scheduleWrite();
                    }
                    QQC2.ToolTip.text: i18n("Forbidden zone the popup never enters, for example behind the taskbar.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.SpinBox {
                    id: leftSpin

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Left:")
                    implicitWidth: 86
                    from: 0
                    to: SharedConf.MAX_MARGIN
                    stepSize: 1
                    editable: true
                    Component.onCompleted: value = marginLeft
                    onValueModified: {
                        marginLeft = value;
                        scheduleWrite();
                    }
                    QQC2.ToolTip.text: i18n("Forbidden zone the popup never enters.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.Button {
                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Calibration:")

                    icon.name: "preferences-desktop"
                    text: i18n("Adjust on screen…")
                    onClicked: configShared.openMarginEditor()
                    QQC2.ToolTip.text: i18n("Drag the bands right on your screen and read exact pixel values.")
                    QQC2.ToolTip.visible: hovered
                }

                SectionHeader {
                    title: i18n("New widgets")
                    note: i18n("Every widget you add to the desktop starts with these settings. Existing widgets are not changed.")
                }

                QQC2.ComboBox {
                    id: defaultSizeBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Size:")
                    textRole: "text"
                    model: [
                        { text: i18n("Small (22 px)"), value: 22 },
                        { text: i18n("Medium (32 px)"), value: 32 },
                        { text: i18n("Large (48 px)"), value: 48 },
                        { text: i18n("Huge (64 px)"), value: 64 },
                        { text: i18n("Very large (96 px)"), value: 96 },
                        { text: i18n("Enormous (128 px)"), value: 128 },
                        { text: i18n("Maximum (256 px)"), value: 256 }
                    ]
                    onActivated: index => {
                        defaultIconSize = model[index].value;
                        scheduleWrite();
                    }
                    Component.onCompleted: configShared.syncSizeBox()
                    QQC2.ToolTip.text: i18n("Icon size given to newly added widgets.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ComboBox {
                    id: defaultGridBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Grid:")
                    textRole: "text"
                    model: [
                        { text: i18n("Auto"), value: "auto" },
                        { text: "2×2", value: "2" },
                        { text: "3×3", value: "3" },
                        { text: "4×4", value: "4" }
                    ]
                    onActivated: index => {
                        defaultGridMode = model[index].value;
                        scheduleWrite();
                    }
                    Component.onCompleted: configShared.syncGridBox()
                    QQC2.ToolTip.text: i18n("Composite grid given to newly added widgets.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ComboBox {
                    id: defaultGridMaxBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Max:")
                    visible: defaultGridMode === "auto"
                    textRole: "text"
                    model: [
                        { text: "2×2", value: 2 },
                        { text: "3×3", value: 3 },
                        { text: "4×4", value: 4 }
                    ]
                    onActivated: index => {
                        defaultGridMax = model[index].value;
                        scheduleWrite();
                    }
                    Component.onCompleted: configShared.syncMaxGridBox()
                    QQC2.ToolTip.text: i18n("Largest grid the automatic mode may pick.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ComboBox {
                    id: defaultSortBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Sorting:")
                    textRole: "text"
                    model: [
                        { text: i18n("Name (A–Z)"), value: "name" },
                        { text: i18n("Name (Z–A)"), value: "nameDesc" },
                        { text: i18n("File name"), value: "file" }
                    ]
                    onActivated: index => {
                        defaultSortMode = model[index].value;
                        scheduleWrite();
                    }
                    Component.onCompleted: configShared.syncSortBox()
                    QQC2.ToolTip.text: i18n("Order of the shortcuts in the icon and the popup.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.CheckBox {
                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Frame:")
                    text: i18n("Around the icons")
                    checked: defaultShowFrame
                    onToggled: {
                        defaultShowFrame = checked;
                        scheduleWrite();
                    }
                }

                QQC2.ComboBox {
                    id: defaultOpenOnHoverBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Open:")
                    textRole: "text"
                    model: [
                        { text: i18n("Click"), value: false },
                        { text: i18n("Hover"), value: true }
                    ]
                    onActivated: index => {
                        defaultOpenOnHover = model[index].value;
                        scheduleWrite();
                    }
                    Component.onCompleted: currentIndex = defaultOpenOnHover ? 1 : 0
                    QQC2.ToolTip.text: i18n("Whether the popup opens on click or on hover.")
                    QQC2.ToolTip.visible: hovered
                }
            }
        }
    }

    MarginEditor {
        id: marginEditor

        onAccepted: screenMargins => {
            configShared.marginTop = screenMargins.top;
            configShared.marginRight = screenMargins.right;
            configShared.marginBottom = screenMargins.bottom;
            configShared.marginLeft = screenMargins.left;
            writeAll();
        }
    }
}
