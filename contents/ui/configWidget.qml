import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs

import org.kde.kirigami as Kirigami

import "code/Paths.js" as Paths

Item {
    id: configWidget

    // the shell config window maps Return to OK; swallow it so typing never closes the dialog
    Keys.onReturnPressed: event => event.accepted = true
    Keys.onEnterPressed: event => event.accepted = true

    property alias cfg_folder: folderField.text
    property alias cfg_labelText: labelField.text
    property bool cfg_openOnHover: false
    property alias cfg_showFrame: frameBox.checked
    property string cfg_popupPlacement: "auto"
    property string cfg_autoPreference: "up"
    property string cfg_gridMode: "auto"
    property int cfg_gridMax: 3
    property string cfg_sortMode: "name"
    property int cfg_autoBias: 12
    property int cfg_iconSize: 64
    QQC2.ScrollView {
        id: pageScroll

        anchors.fill: parent

        ColumnLayout {
            id: formColumn

            width: pageScroll.availableWidth
            spacing: 0

            Kirigami.FormLayout {
                Layout.fillWidth: true

                SectionHeader {
                    title: i18n("Folder")
                    first: true
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Path:")

                    QQC2.TextField {
                        id: folderField

                        Layout.fillWidth: true
                        hoverEnabled: true
                        placeholderText: "/home/user/folder"
                        QQC2.ToolTip.text: i18n("Folder with .desktop application shortcuts. Create it anywhere and drop launchers into it.")
                        QQC2.ToolTip.visible: hovered
                    }

                    QQC2.Button {
                        hoverEnabled: true
                        icon.name: "folder-open"
                        text: i18n("Browse…")
                        onClicked: {
                            const start = Paths.pathToUrl(folderField.text.trim());
                            if (start !== "") {
                                folderDialog.currentFolder = start;
                            }
                            folderDialog.open();
                        }
                        QQC2.ToolTip.text: i18n("Pick the folder on disk.")
                        QQC2.ToolTip.visible: hovered
                    }
                }

                QQC2.TextField {
                    id: labelField

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Label:")
                    placeholderText: i18n("Same as folder name if empty")
                    QQC2.ToolTip.text: i18n("Text under the icon; leave empty to use the folder name.")
                    QQC2.ToolTip.visible: hovered
                }

                SectionHeader {
                    title: i18n("Icon")
                }

                QQC2.ComboBox {
                    id: iconSizeBox

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
                    onActivated: index => cfg_iconSize = model[index].value
                    Component.onCompleted: {
                        for (let i = 0; i < model.length; ++i) {
                            if (model[i].value === cfg_iconSize) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }
                    QQC2.ToolTip.text: i18n("Match your desktop icon size for a perfect fit.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ComboBox {
                    id: gridBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Grid:")
                    textRole: "text"
                    model: [
                        { text: i18n("Auto"), value: "auto" },
                        { text: "2×2", value: "2" },
                        { text: "3×3", value: "3" },
                        { text: "4×4", value: "4" }
                    ]
                    onActivated: index => cfg_gridMode = model[index].value
                    Component.onCompleted: {
                        for (let i = 0; i < model.length; ++i) {
                            if (model[i].value === cfg_gridMode) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }
                    QQC2.ToolTip.text: i18n("How many mini-icons the composite shows. Auto grows with the folder contents.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ComboBox {
                    id: maxGridBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Max:")
                    visible: cfg_gridMode === "auto"
                    textRole: "text"
                    model: [
                        { text: "2×2", value: 2 },
                        { text: "3×3", value: 3 },
                        { text: "4×4", value: 4 }
                    ]
                    onActivated: index => cfg_gridMax = model[index].value
                    Component.onCompleted: {
                        for (let i = 0; i < model.length; ++i) {
                            if (model[i].value === cfg_gridMax) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }
                    QQC2.ToolTip.text: i18n("Largest grid the automatic mode may pick.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ComboBox {
                    id: sortBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Sorting:")
                    textRole: "text"
                    model: [
                        { text: i18n("Name (A–Z)"), value: "name" },
                        { text: i18n("Name (Z–A)"), value: "nameDesc" },
                        { text: i18n("File name"), value: "file" }
                    ]
                    onActivated: index => cfg_sortMode = model[index].value
                    Component.onCompleted: {
                        for (let i = 0; i < model.length; ++i) {
                            if (model[i].value === cfg_sortMode) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }
                    QQC2.ToolTip.text: i18n("Order of the shortcuts in the icon and the popup.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.CheckBox {
                    id: frameBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Frame:")
                    text: i18n("Around the icons")
                    QQC2.ToolTip.text: i18n("Semi-transparent card behind the mini-icons.")
                    QQC2.ToolTip.visible: hovered
                }

                SectionHeader {
                    title: i18n("Popup")
                }

                QQC2.ComboBox {
                    id: openBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Open:")
                    textRole: "text"
                    model: [
                        { text: i18n("Click"), value: false },
                        { text: i18n("Hover"), value: true }
                    ]
                    onActivated: index => cfg_openOnHover = model[index].value
                    Component.onCompleted: currentIndex = cfg_openOnHover ? 1 : 0
                    QQC2.ToolTip.text: i18n("Whether the popup opens on click or on hover.")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ComboBox {
                    id: placementBox

                    hoverEnabled: true
                    Kirigami.FormData.label: i18n("Position:")
                    textRole: "text"
                    model: [
                        { text: i18n("Auto"), value: "auto" },
                        { text: i18n("Above"), value: "up" },
                        { text: i18n("Below"), value: "down" },
                        { text: i18n("To the left"), value: "left" },
                        { text: i18n("To the right"), value: "right" }
                    ]
                    onActivated: index => cfg_popupPlacement = model[index].value
                    Component.onCompleted: {
                        for (let i = 0; i < model.length; ++i) {
                            if (model[i].value === cfg_popupPlacement) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }
                    QQC2.ToolTip.text: i18n("Where the popup appears relative to the widget.")
                    QQC2.ToolTip.visible: hovered
                }

                // preference and strength only apply in auto mode, so the two rows hide otherwise
                QQC2.ComboBox {
                    id: preferenceBox

                    hoverEnabled: true
                    visible: cfg_popupPlacement === "auto"
                    Kirigami.FormData.label: i18n("Preference:")
                    textRole: "text"
                    model: [
                        { text: i18n("Up"), value: "up" },
                        { text: i18n("Down"), value: "down" },
                        { text: i18n("To the left"), value: "left" },
                        { text: i18n("To the right"), value: "right" }
                    ]
                    onActivated: index => cfg_autoPreference = model[index].value
                    Component.onCompleted: {
                        for (let i = 0; i < model.length; ++i) {
                            if (model[i].value === cfg_autoPreference) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }
                    QQC2.ToolTip.text: i18n("Side that wins when several sides are equally good.")
                    QQC2.ToolTip.visible: hovered
                }

                RowLayout {
                    visible: cfg_popupPlacement === "auto"
                    Kirigami.FormData.label: i18n("Strength:")

                    QQC2.Slider {
                        id: biasSlider

                        hoverEnabled: true
                        from: 0
                        to: 40
                        stepSize: 1

                        onMoved: cfg_autoBias = value

                        Component.onCompleted: value = cfg_autoBias

                        QQC2.ToolTip.text: i18n("How far the preferred side may lag behind the best one and still win, in percent. 0 — always the nearest screen edge wins.")
                        QQC2.ToolTip.visible: hovered
                    }

                    QQC2.Label {
                        text: biasSlider.value + i18n("%")
                    }
                }
            }
        }
    }

    // dialog declared at page root: popups are not layout items
    FolderDialog {
        id: folderDialog

        title: i18n("Choose Folder")
        onAccepted: folderField.text = Paths.urlToPath(selectedFolder)
    }
}
