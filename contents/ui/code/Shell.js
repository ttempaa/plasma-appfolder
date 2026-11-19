.pragma library

// POSIX single quoting: everything but the quote itself passes verbatim
// inside '…', so only ' needs the '\'' escape
function quote(s) {
    return "'" + s.replace(/'/g, "'\\''") + "'";
}
