import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

// Section header styled after what FormLayout renders for FormData sections
// (Kirigami.Heading level 3 / Primary, centered), so every tab looks the same;
// the optional note goes into a tooltip marked by the small icon
ColumnLayout {
    id: header

    property string title
    property string info: ""
    property bool first: false

    Kirigami.FormData.isSection: true

    spacing: Math.round(Kirigami.Units.smallSpacing / 2)

    // the whitespace FormLayout puts before a textual section header
    Item {
        Layout.preferredHeight: Kirigami.Units.largeSpacing * 2
        visible: !header.first
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            level: 3
            type: Kirigami.Heading.Type.Primary
            text: header.title
        }

        Kirigami.Icon {
            visible: header.info !== ""
            source: "help-whatsthis"
            color: Kirigami.Theme.textColor
            opacity: 0.6
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }

        HoverHandler {
            id: noteHover
        }

        QQC2.ToolTip.visible: noteHover.hovered && header.info !== ""
        QQC2.ToolTip.text: header.info
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }
}
