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

    // resolves from the parse cache when possible; returns false when the
    // file still needs reading — the owner feeds the text back via
    // applyText()/applyFileName(), files are read in one batch
    function restoreFromCache() {
        name = "";
        icon = "";
        isApplication = false;
        unreadable = false;
        const cached = DesktopFile.fromCache(info.source.toString());
        if (cached !== undefined) {
            apply(cached);
            return true;
        }
        return false;
    }

    function applyText(text) {
        apply(DesktopFile.cachedParse(info.source.toString(), text, Qt.locale()));
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
