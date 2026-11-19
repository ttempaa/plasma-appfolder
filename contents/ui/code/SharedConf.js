.pragma library

// Everything the widget family owns lives under one data dir:
// ~/.local/share/plasma-appfolder/ — appfolder.conf and auto-created launcher folders
var DATA_DIR = "plasma-appfolder";
var FILE = "appfolder.conf";
var GROUP = "General";
var KEYS = ["marginTop", "marginRight", "marginBottom", "marginLeft"];
var DEFAULTS_GROUP = "Defaults";
var DEFAULTS_KEYS = ["iconSize", "gridMode", "gridMax", "sortMode", "showFrame", "openOnHover"];
// must mirror the <default> entries of these keys in contents/config/main.xml
var BASE_DEFAULTS = {
    iconSize: 64,
    gridMode: "auto",
    gridMax: 3,
    sortMode: "name",
    showFrame: true,
    openOnHover: false
};
// upper bound for a screen margin, shared by the spinboxes and the calibrator
var MAX_MARGIN = 500;

// returns normalized margins (0 for absent keys), parsed shared defaults
// and the flags, or null when unparsable
function _normalize(raw) {
    var vals = {};
    for (var i = 0; i < KEYS.length; ++i) {
        var s = raw[KEYS[i]];
        if (s === undefined || s === "") {
            vals[KEYS[i]] = 0;
            continue;
        }
        var n = parseInt(s, 10);
        if (isNaN(n)) {
            return null;
        }
        vals[KEYS[i]] = Math.max(0, n);
    }
    var gridModes = ["auto", "2", "3", "4"];
    var sortModes = ["name", "nameDesc", "file"];
    var bools = ["true", "false"];
    vals.__anyDefault = false;
    vals.__defaultsConfigured = raw.__configured === "true";
    vals.dIconSize = null;
    vals.dGridMode = null;
    vals.dGridMax = null;
    vals.dSortMode = null;
    vals.dShowFrame = null;
    vals.dOpenOnHover = null;
    var size = parseInt(raw.dIconSize, 10);
    if (!isNaN(size) && size >= 8) {
        vals.dIconSize = size;
        vals.__anyDefault = true;
    }
    if (gridModes.indexOf(raw.dGridMode) !== -1) {
        vals.dGridMode = raw.dGridMode;
        vals.__anyDefault = true;
    }
    var gridMax = parseInt(raw.dGridMax, 10);
    if (!isNaN(gridMax) && gridMax >= 2 && gridMax <= 4) {
        vals.dGridMax = gridMax;
        vals.__anyDefault = true;
    }
    if (sortModes.indexOf(raw.dSortMode) !== -1) {
        vals.dSortMode = raw.dSortMode;
        vals.__anyDefault = true;
    }
    if (bools.indexOf(raw.dShowFrame) !== -1) {
        vals.dShowFrame = (raw.dShowFrame === "true");
        vals.__anyDefault = true;
    }
    if (bools.indexOf(raw.dOpenOnHover) !== -1) {
        vals.dOpenOnHover = (raw.dOpenOnHover === "true");
        vals.__anyDefault = true;
    }
    return vals;
}

function dataHome() {
    // shell expression, expanded when the command runs
    return "\"${XDG_DATA_HOME:-$HOME/.local/share}/" + DATA_DIR + "\"";
}

// one cat spawn reads the whole file, the INI is parsed in JS; writes
// shell out to kwriteconfig6
function readAllCmd() {
    return "cat " + dataHome() + "/" + FILE;
}

// creates the data dir and a fresh "applications[-N]" folder and prints
// its path on stdout, then the desktop containment's icon-size index from
// the appletsrc — to size a fresh widget like the desktop
function managedFolderCmd() {
    return "d=" + dataHome() + "; mkdir -p \"$d\"; n=applications; i=1;"
        + " while [ -e \"$d/$n\" ]; do i=$((i+1)); n=applications-$i; done;"
        + " mkdir \"$d/$n\" && printf '%s\\n' \"$d/$n\";"
        + " awk '/^\\[Containments\\]\\[[0-9]+\\]$/{c=$0;f=0}"
        + " /^plugin=org\\.kde\\.plasma\\.folder/{f=1}"
        + " /^\\[Containments\\]\\[[0-9]+\\]\\[General\\]$/{g=(f?c:\"\")}"
        + " /^iconSize=/{if(g!=\"\"){print substr($0,10); g=\"\"}}'"
        + " \"${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc\" 2>/dev/null | head -1";
}

// raw: { marginTop: "25"|undefined, dIconSize: "96"|undefined, ... };
// keys outside the two known groups are ignored, comments included
function parseIni(text) {
    var raw = {};
    var group = "";
    var lines = text.split("\n");
    for (var i = 0; i < lines.length; ++i) {
        var line = lines[i].trim();
        if (line === "" || line.charAt(0) === "#" || line.charAt(0) === ";") {
            continue;
        }
        if (line.charAt(0) === "[") {
            var close = line.indexOf("]");
            group = close > 1 ? line.slice(1, close) : "";
            continue;
        }
        var eq = line.indexOf("=");
        if (eq < 1) {
            continue;
        }
        var k = line.slice(0, eq).trim();
        var v = line.slice(eq + 1).trim();
        if (group === GROUP && KEYS.indexOf(k) !== -1) {
            raw[k] = v;
        } else if (group === DEFAULTS_GROUP && k === "configured") {
            raw.__configured = v;
        } else if (group === DEFAULTS_GROUP && DEFAULTS_KEYS.indexOf(k) !== -1) {
            raw["d" + k.charAt(0).toUpperCase() + k.slice(1)] = v;
        }
    }
    return raw;
}

function parseAll(stdout) {
    return _normalize(parseIni(stdout));
}

function writeMarginsCmd(vals) {
    var parts = [];
    for (var i = 0; i < KEYS.length; ++i) {
        parts.push("kwriteconfig6 --file " + dataHome() + "/" + FILE + " --group " + GROUP
            + " --key " + KEYS[i] + " " + vals[KEYS[i]]);
    }
    return parts.join("; ");
}

// d = { iconSize, gridMode, gridMax, sortMode, showFrame, openOnHover } — all plain values
function writeDefaultsCmd(d) {
    var f = dataHome() + "/" + FILE;
    var parts = [
        // tombstone: once shared defaults are saved, the desktop-size detection for new widgets stays off
        "kwriteconfig6 --file " + f + " --group " + DEFAULTS_GROUP
            + " --key configured true"
    ];
    // the file holds only intentional deviations: a key matching the built-in default is deleted, not written
    for (var i = 0; i < DEFAULTS_KEYS.length; ++i) {
        var k = DEFAULTS_KEYS[i];
        var val = (typeof d[k] === "boolean") ? (d[k] ? "true" : "false") : d[k];
        if (String(val) === String(BASE_DEFAULTS[k])) {
            parts.push("kwriteconfig6 --file " + f + " --group " + DEFAULTS_GROUP
                + " --key " + k + " --delete");
        } else {
            parts.push("kwriteconfig6 --file " + f + " --group " + DEFAULTS_GROUP
                + " --key " + k + " " + val);
        }
    }
    return parts.join("; ");
}
