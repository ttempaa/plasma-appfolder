import QtQuick
import QtQuick.Controls as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

import "code/Icons.js" as Icons

PlasmaCore.Dialog {
    id: popup

    property var apps: []
    property int cellPx: 64
    property int cols: 2
    property int maxVisibleRows: 5

    signal launched(var info)
    signal hovered(bool hovered)

    // pre-show size estimation before the dialog has a frame geometry
    readonly property alias contentImplicitWidth: popupContent.implicitWidth
    readonly property alias contentImplicitHeight: popupContent.implicitHeight

    location: PlasmaCore.Types.Floating
    // the popup must survive focus loss while a launcher is dragged out of it
    hideOnWindowDeactivate: !dragging
    visible: false

    property bool dragging: false

    mainItem: Item {
        id: popupContent

        readonly property int iconPx: Icons.stepDown(popup.cellPx * 0.58)
        // one-line rows land exactly on cellPx
        readonly property int rowPadding: Math.max(
            0,
            popup.cellPx - Kirigami.Units.smallSpacing * 2 - iconPx - Math.ceil(popupLabelMetrics.height)
        )

        readonly property var rows: {
            const chunks = [];
            for (let i = 0; i < popup.apps.length; i += popup.cols) {
                chunks.push(popup.apps.slice(i, i + popup.cols));
            }
            return chunks.length > 0 ? chunks : [[]];
        }

        implicitWidth: popup.cols * popup.cellPx + Kirigami.Units.largeSpacing * 2
        implicitHeight: Math.min(
            Math.max(contentColumn.implicitHeight, emptyLabel.visible ? emptyLabel.implicitHeight : 0),
            popup.maxVisibleRows * popup.cellPx
        ) + Kirigami.Units.largeSpacing * 2

        // the dialog overwrites width/height with explicit values once shown
        width: implicitWidth
        height: implicitHeight

        HoverHandler {
            onHoveredChanged: popup.hovered(hovered)
        }

        FontMetrics {
            id: popupLabelMetrics
        }

        Flickable {

            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            clip: true
            contentWidth: width
            contentHeight: contentColumn.implicitHeight
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

            Column {
                id: contentColumn

                Repeater {
                    model: popupContent.rows

                    Row {
                        Repeater {
                            model: modelData

                            Item {
                                id: tile

                                width: popup.cellPx
                                height: tileColumn.implicitHeight + popupContent.rowPadding

                                Column {
                                    id: tileColumn

                                    anchors.top: parent.top
                                    anchors.topMargin: Kirigami.Units.smallSpacing
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: Kirigami.Units.smallSpacing

                                    // stock size only: scaled icons resample into blur
                                    Kirigami.Icon {
                                        id: appIcon

                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: popupContent.iconPx
                                        height: width
                                        source: modelData ? modelData.icon : ""
                                    }

                                    PlasmaExtras.ShadowedLabel {
                                        width: tile.width
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                        text: modelData ? modelData.name : ""
                                    }
                                }

                                // dropping the tile elsewhere moves the file out of the folder;
                                // with dragType Automatic, setting Drag.active starts the native drag
                                Drag.dragType: Drag.Automatic
                                Drag.mimeData: {
                                    "text/uri-list": modelData ? modelData.source.toString() : ""
                                }
                                Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
                                Drag.onDragStarted: popup.dragging = true
                                Drag.onDragFinished: popup.dragging = false

                                // a press that moved past the threshold is a drag: the release must not launch
                                property bool dragOut: false

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor

                                    property point pressPos

                                    onPressed: (mouse) => {
                                        pressPos = Qt.point(mouse.x, mouse.y);
                                        tile.dragOut = false;
                                    }
                                    onPositionChanged: (mouse) => {
                                        if (
                                            !tile.dragOut &&
                                            (Math.abs(mouse.x - pressPos.x) >= 10 || Math.abs(mouse.y - pressPos.y) >= 10)
                                        ) {
                                            tile.dragOut = true;
                                            // best-effort pixmap: a grab losing the race goes without one
                                            appIcon.grabToImage(result => {
                                                tile.Drag.imageSource = result.url;
                                            });
                                            tile.Drag.active = true;
                                        }
                                    }
                                    onClicked: {
                                        if (!tile.dragOut) {
                                            popup.launched(modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        QQC2.Label {
            id: emptyLabel

            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 3
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: popup.apps.length === 0
            text: i18n("The folder is empty.\nPut application shortcuts here.")
        }
    }
}
