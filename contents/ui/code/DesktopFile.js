.pragma library

// .desktop entry parser: pure text-to-values, no QML context, no i18n;
// fallbacks are layered by callers on top of the raw values.

.import "Shell.js" as Shell

// url -> last parse result, shared for the engine's lifetime
var cache = {};

function parse(text, locale) {
    const lines = text.split("\n");
    let name = "";
    let nameFull = "";
    let nameLang = "";
    let icon = "";
    let type = "";
    let locName = "";
    let locLang = "";
    if (locale && locale.name) {
        locName = locale.name;
        locLang = locName.split("_")[0];
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
        } else if (locName !== "" && line.startsWith("Name[" + locName + "]=")) {
            nameFull = line.slice(7 + locName.length).trim();
        } else if (locLang !== "" && line.startsWith("Name[" + locLang + "]=")) {
            nameLang = line.slice(7 + locLang.length).trim();
        } else if (line.startsWith("Name=")) {
            name = line.slice(5).trim();
        } else if (line.startsWith("Icon=")) {
            icon = line.slice(5).trim();
        }
    }
    return {
        name: nameFull || nameLang || name,
        icon: icon,
        valid: !type || type === "Application"
    };
}

// cache probe without touching the filesystem: lets AppInfo reapply a
// previous parse synchronously after rebuilds and reordering; a .desktop
// edited on disk keeps serving the old parse until the engine restarts
function lookup(url) {
    const key = url.toString();
    if (Object.prototype.hasOwnProperty.call(cache, key)) {
        return cache[key];
    }
    return undefined;
}

function cachedParse(url, text, locale) {
    const hit = lookup(url);
    if (hit !== undefined) {
        return hit;
    }
    const parsed = parse(text, locale);
    cache[url.toString()] = parsed;
    return parsed;
}

// one shell command that dumps every file with a ===<path> marker line
// before each — a single process for the whole folder; keys in .desktop
// syntax cannot start with "=", so a marker line is unambiguous
function catCmd(paths) {
    const parts = [];
    for (let i = 0; i < paths.length; ++i) {
        const quoted = Shell.quote(paths[i]);
        parts.push("printf '\\n===%s\\n' " + quoted + "; cat " + quoted);
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

// visible-launcher list for the composite and the popup: entries that
// are still loading or known non-applications are dropped, fallback ones
// (unreadable files degraded to their filename) stay; "name"/"nameDesc"
// sort by display name, "file" keeps the model's file-name order
function sortedVisible(list, mode) {
    const out = [];
    for (let i = 0; i < list.length; ++i) {
        const item = list[i];
        if (item && item.name !== "" && (item.valid || item.fallback)) {
            out.push(item);
        }
    }
    if (mode !== "file") {
        out.sort((a, b) => {
            const an = a.name.toLowerCase();
            const bn = b.name.toLowerCase();
            return an < bn ? -1 : an > bn ? 1 : 0;
        });
        if (mode === "nameDesc") {
            out.reverse();
        }
    }
    return out;
}
