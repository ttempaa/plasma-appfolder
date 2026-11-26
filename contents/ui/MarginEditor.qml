import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "code/SharedConf.js" as SharedConf

// Full-screen margin calibrator; single-screen assumption.
PlasmaCore.Dialog {
    id: marginEditor

    property var screenMargins: ({ top: 0, right: 0, bottom: 0, left: 0 })

    signal accepted(var screenMargins)

    visible: false
    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.Normal
    backgroundHints: PlasmaCore.Types.NoBackground
    hideOnWindowDeactivate: false

    function open(screenWidth, screenHeight) {
        // the screen size comes via arguments: before the dialog is shown,
        // the Screen attached property would fall back to the default
        editorRoot.implicitWidth = screenWidth;
        editorRoot.implicitHeight = screenHeight;
        marginEditor.x = 0;
        marginEditor.y = 0;
        draft.top = screenMargins.top;
        draft.right = screenMargins.right;
        draft.bottom = screenMargins.bottom;
        draft.left = screenMargins.left;
        marginEditor.visible = true;
        editorRoot.forceActiveFocus();
    }

    function finish() {
        marginEditor.accepted({
            top: draft.top,
            right: draft.right,
            bottom: draft.bottom,
            left: draft.left
        });
        marginEditor.visible = false;
    }

    // one screen edge: the visible band plus its grab zone, reaching 64px
    // past the band so it stays grabbable above an always-on-top panel
    component Band: Item {
        id: band

        property string side
        property int value: 0
        signal dragged(int v)

        readonly property bool vertical: side === "top" || side === "bottom"
        readonly property bool atStart: side === "top" || side === "left"
        readonly property int reach: value + 64

        z: 10
        x: vertical ? 0 : (atStart ? 0 : parent.width - reach)
        y: vertical ? (atStart ? 0 : parent.height - reach) : 0
        width: vertical ? parent.width : reach
        height: vertical ? reach : parent.height

        Rectangle {
            x: band.vertical ? 0 : (band.atStart ? 0 : parent.width - band.value)
            y: band.vertical ? (band.atStart ? 0 : parent.height - band.value) : 0
            width: band.vertical ? parent.width : band.value
            height: band.vertical ? band.value : parent.height
            color: Kirigami.Theme.highlightColor
            opacity: 0.45
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: band.vertical ? Qt.SizeVerCursor : Qt.SizeHorCursor
            onPositionChanged: mouse => {
                if (pressed) {
                    const pt = mapToItem(band.parent, mouse.x, mouse.y);
                    band.dragged(band.vertical
                        ? (band.atStart ? pt.y : band.parent.height - pt.y)
                        : (band.atStart ? pt.x : band.parent.width - pt.x));
                }
            }
        }
    }

    // value badge sitting on the inner edge of its band
    component Pill: Rectangle {
        id: pill

        property string side
        property int value: 0

        readonly property bool vertical: side === "top" || side === "bottom"

        z: 15
        width: pillRow.implicitWidth + Kirigami.Units.largeSpacing * 1.5
        height: Math.round(Kirigami.Units.gridUnit * 1.4)
        radius: height / 2
        color: Kirigami.Theme.highlightColor

        x: vertical ? (parent.width - width) / 2
            : (side === "left"
                ? Math.max(Kirigami.Units.smallSpacing, value - width / 2)
                : Math.min(parent.width - width - Kirigami.Units.smallSpacing, parent.width - value - width / 2))
        y: vertical
            ? (side === "top"
                ? Math.max(Kirigami.Units.smallSpacing, value - height / 2)
                : Math.min(parent.height - height - Kirigami.Units.smallSpacing, parent.height - value - height / 2))
            : (parent.height - height) / 2

        RowLayout {
            id: pillRow

            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 16
                implicitHeight: 16
                source: pill.vertical ? "transform-move-vertical" : "transform-move-horizontal"
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignVCenter
                color: "white"
                font.bold: true
                text: pill.value
            }
        }
    }

    mainItem: Item {
        id: editorRoot

        QtObject {
            id: draft

            property int top: 0
            property int right: 0
            property int bottom: 0
            property int left: 0

            function clamp(v) {
                return Math.max(0, Math.min(SharedConf.MAX_MARGIN, Math.round(v)));
            }
        }

        implicitWidth: 1920
        implicitHeight: 1080

        Keys.onEscapePressed: marginEditor.finish()

        Rectangle {
            z: -1
            anchors.fill: parent
            color: "#000000"
            opacity: 0.3
        }

        Band {
            side: "top"
            value: draft.top
            onDragged: v => draft.top = draft.clamp(v)
        }

        Band {
            side: "bottom"
            value: draft.bottom
            onDragged: v => draft.bottom = draft.clamp(v)
        }

        Band {
            side: "left"
            value: draft.left
            onDragged: v => draft.left = draft.clamp(v)
        }

        Band {
            side: "right"
            value: draft.right
            onDragged: v => draft.right = draft.clamp(v)
        }

        Pill { side: "top"; value: draft.top }
        Pill { side: "bottom"; value: draft.bottom }
        Pill { side: "left"; value: draft.left }
        Pill { side: "right"; value: draft.right }

        Rectangle {
            z: 20
            anchors.centerIn: parent
            width: controlColumn.implicitWidth + Kirigami.Units.gridUnit * 2
            height: controlColumn.implicitHeight + Kirigami.Units.gridUnit
            radius: Kirigami.Units.largeSpacing
            color: "#e0222222"
            border.width: 1
            border.color: "#40ffffff"

            ColumnLayout {
                id: controlColumn

                anchors.centerIn: parent
                spacing: Kirigami.Units.largeSpacing

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    color: "white"
                    text: i18n("Drag the bands to where the popup must not go, then press Done or Esc")
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.largeSpacing

                    QQC2.Button {
                        icon.name: "edit-clear-all"
                        text: i18n("Reset")
                        onClicked: {
                            draft.top = 0;
                            draft.right = 0;
                            draft.bottom = 0;
                            draft.left = 0;
                        }
                    }

                    QQC2.Button {
                        icon.name: "dialog-ok"
                        text: i18n("Done")
                        onClicked: marginEditor.finish()
                    }
                }
            }
        }
    }
}
