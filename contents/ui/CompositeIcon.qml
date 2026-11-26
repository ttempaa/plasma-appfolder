import QtQuick

import org.kde.kirigami as Kirigami

import "code/Icons.js" as Icons

Item {
    id: comp

    property int cellPx: 64
    property int cols: 2
    property int count: 0
    property bool showFrame: true
    property var icons: []

    width: cellPx
    height: cellPx

    // icon size solves to a stock pixmap size (icons render 1:1), spacing flexes to absorb the rest
    readonly property var geometry: Icons.compositeGeometry(width, cols, showFrame)

    Rectangle {
        anchors.fill: parent
        radius: Math.round(width * 0.16)
        color: Kirigami.Theme.backgroundColor
        opacity: 0.28
        border.width: Math.max(1, Math.round(width / 64))
        border.color: Kirigami.Theme.textColor
        visible: comp.showFrame
    }

    // empty state: ghost squares where the mini-icons will appear once launchers are added
    Grid {
        anchors.fill: parent
        anchors.margins: comp.geometry.inset
        columns: comp.cols
        columnSpacing: comp.geometry.gap
        rowSpacing: comp.geometry.gap
        visible: comp.count === 0

        Repeater {
            model: comp.cols * comp.cols

            Rectangle {
                width: comp.geometry.size
                height: comp.geometry.size
                radius: Math.round(width * 0.22)
                color: Kirigami.Theme.textColor
                opacity: 0.2
            }
        }
    }

    Grid {
        // deliberate grid spacing: breeze icons carry baked-in transparent margins, zero gap would read as seams
        anchors.fill: parent
        anchors.margins: comp.geometry.inset
        columns: comp.cols
        columnSpacing: comp.geometry.gap
        rowSpacing: comp.geometry.gap
        visible: comp.count > 0

        Repeater {
            model: Math.min(comp.count, comp.cols * comp.cols)

            Kirigami.Icon {
                width: comp.geometry.size
                height: comp.geometry.size
                source: comp.icons[index] || ""
            }
        }
    }
}
