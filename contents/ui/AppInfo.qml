import QtQuick

import "code/DesktopFile.js" as DesktopFile
import "code/Paths.js" as Paths

QtObject {
    id: info

    property url source
    property string name
    property string icon
    // false for .desktop entries that are not applications (Type=Link etc.)
    property bool isApplication
    // the file could not be read: stays visible under its file name instead of hiding
    property bool unreadable
    property bool dead

    function applyText(text) {
        apply(DesktopFile.parse(text, Qt.locale()));
    }

    function apply(parsed) {
        isApplication = parsed.isApplication;
        if (parsed.isApplication) {
            name = parsed.name || i18n("Unknown");
            icon = parsed.icon || "application-x-desktop";
        } else {
            name = "";
            icon = "";
        }
    }

    function applyFileName() {
        const raw = info.source.toString();
        const base = Paths.percentDecode(Paths.basename(raw).replace(/\.desktop$/i, ""));
        name = base;
        icon = base;
        unreadable = true;
    }
}
