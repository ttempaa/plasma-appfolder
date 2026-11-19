import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Widget")
        icon: "preferences-desktop"
        source: "configWidget.qml"
    }
    ConfigCategory {
        name: i18n("Common")
        icon: "preferences-other"
        source: "configShared.qml"
    }
}
