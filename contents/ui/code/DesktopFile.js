.pragma library

.import "Paths.js" as Paths
.import "Shell.js" as Shell

function parse(text, locale) {
    const lines = text.split("\n");
    let name = "";
    let nameFull = "";
    let nameLanguage = "";
    let icon = "";
    let type = "";
    let localeName = "";
    let localeLanguage = "";
    if (locale && locale.name) {
        localeName = locale.name;
        localeLanguage = localeName.split("_")[0];
    }
    // only the [Desktop Entry] group describes the launcher; Name=/Icon=
    // under later headers ([Desktop Action ...]) belong to those actions
    // and must not override the real name or icon
    let inEntry = false;
    for (let i = 0; i < lines.length; ++i) {
        const line = lines[i].trim();
        if (line.charAt(0) === "[") {
            if (line === "[Desktop Entry]") {
                inEntry = true;
            } else if (inEntry) {
                break;
            }
            continue;
        }
        if (!inEntry) {
            continue;
        }
        if (line.startsWith("Type=")) {
            type = line.slice(5);
        } else if (localeName !== "" && line.startsWith("Name[" + localeName + "]=")) {
            nameFull = line.slice(7 + localeName.length).trim();
        } else if (localeLanguage !== "" && line.startsWith("Name[" + localeLanguage + "]=")) {
            nameLanguage = line.slice(7 + localeLanguage.length).trim();
        } else if (line.startsWith("Name=")) {
            name = line.slice(5).trim();
        } else if (line.startsWith("Icon=")) {
            icon = line.slice(5).trim();
        }
    }
    return {
        name: nameFull || nameLanguage || name,
        icon: icon,
        isApplication: !type || type === "Application"
    };
}

// one shell command that dumps every file with a ===<path> marker line
// before each — a single process for the whole folder; keys in .desktop
// syntax cannot start with "=", so a marker line is unambiguous
// [ -f ]: the model lists symlinks to fifos, cat would hang on them
function catCmd(paths) {
    const parts = [];
    for (let i = 0; i < paths.length; ++i) {
        const quoted = Shell.quote(paths[i]);
        parts.push("printf '\\n===%s\\n' " + quoted);
        parts.push("[ -f " + quoted + " ] && cat " + quoted);
    }
    return parts.join("; ");
}

// stdout of catCmd -> { path: text }; records without content mean the file was unreadable
function parseCat(stdout) {
    const out = {};
    const lines = stdout.split("\n");
    let cur = null;
    let buf = [];
    for (let i = 0; i < lines.length; ++i) {
        if (lines[i].indexOf("===") === 0) {
            if (cur !== null) {
                out[cur] = buf.join("\n");
            }
            cur = lines[i].slice(3);
            buf = [];
        } else if (cur !== null) {
            buf.push(lines[i]);
        }
    }
    if (cur !== null) {
        out[cur] = buf.join("\n");
    }
    return out;
}

// visible-app list for the composite and the popup: entries that are
// still loading or known non-applications are dropped, unreadable ones
// (degraded to their file name) stay; "name"/"nameDesc" sort by display
// name, "file" keeps the file-name order
function visibleApps(list, sortMode) {
    const out = [];
    for (let i = 0; i < list.length; ++i) {
        const item = list[i];
        if (item && item.name !== "" && (item.isApplication || item.unreadable)) {
            out.push(item);
        }
    }
    if (sortMode !== "file") {
        out.sort((a, b) => {
            const an = a.name.toLowerCase();
            const bn = b.name.toLowerCase();
            return an < bn ? -1 : an > bn ? 1 : 0;
        });
        if (sortMode === "nameDesc") {
            out.reverse();
        }
    }
    return out;
}

// kmimetypefinder gives the same verdict as Dolphin and the desktop;
// it blocks on a fifo, hence [ -f ]
function launcherCondition(path) {
    const quotedPath = Shell.quote(path);
    const detectedMime = "\"$(kmimetypefinder -- " + quotedPath + " 2>/dev/null)\"";
    return "[ -f " + quotedPath + " ] && [ " + detectedMime + " = application/x-desktop ]";
}

// the folder model lists the .desktop suffix only
function dropCmd(urls, folderUrl) {
    const withSuffix = [];
    const cmds = [];
    for (let i = 0; i < urls.length; ++i) {
        const u = urls[i].toString();
        if (!u.startsWith("file://")) {
            continue;
        }
        if (u.toLowerCase().endsWith(".desktop")) {
            withSuffix.push(Shell.quote(u));
        } else {
            const destUrl = folderUrl.replace(/\/+$/, "") + "/" + Paths.basename(u) + ".desktop";
            const condition = launcherCondition(Paths.urlToPath(u));
            const move = "kioclient mv " + Shell.quote(u) + " " + Shell.quote(destUrl);
            cmds.push("if " + condition + "; then " + move + "; fi");
        }
    }
    if (withSuffix.length > 0) {
        cmds.unshift("kioclient mv " + withSuffix.join(" ") + " " + Shell.quote(folderUrl));
    }
    return cmds.join("; ");
}
