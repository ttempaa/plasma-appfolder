.pragma library

// decodeURIComponent throws on a literal '%'; the raw string is the best guess
function safeDecode(s) {
    try {
        return decodeURIComponent(s);
    } catch (e) {
        return s;
    }
}

function urlToPath(u) {
    const s = u.toString();
    return s.startsWith("file://") ? safeDecode(s.slice(7)) : s;
}

function pathToUrl(p) {
    try {
        return Qt.url("file://" + p);
    } catch (e) {
        return "";
    }
}

function basename(path) {
    const parts = path.replace(/\/+$/, "").split("/");
    return parts[parts.length - 1] || "/";
}
