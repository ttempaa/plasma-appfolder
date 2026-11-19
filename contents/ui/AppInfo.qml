import QtQuick

import "code/DesktopFile.js" as DesktopFile
import "code/Paths.js" as Paths

QtObject {
    id: info

    property url source
    property string name
    property string icon
    // false for .desktop entries that are not applications (Type=Link etc.)
    property bool valid
    // the file could not be read: stays visible with the filename fallback instead of hiding as invalid
    property bool fallback
    property bool dead

    // resolves from the parse cache when possible; returns false when the
    // file still needs reading — the owner feeds the text back via
    // applyText()/applyFallback(), files are read in one batch
    function load() {
        name = "";
        icon = "";
        valid = false;
        fallback = false;
        const cached = DesktopFile.lookup(info.source.toString());
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
        valid = parsed.valid;
        if (parsed.valid) {
            name = parsed.name || i18n("Unknown");
            icon = parsed.icon || "application-x-desktop";
        } else {
            name = "";
            icon = "";
        }
    }

    function applyFallback() {
        const raw = info.source.toString();
        const base = Paths.safeDecode(raw.slice(raw.lastIndexOf("/") + 1).replace(/\.desktop$/i, ""));
        name = base;
        icon = base;
        fallback = true;
    }
}
