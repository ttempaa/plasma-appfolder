.pragma library

// KIconLoader paints icons from the theme's stock pixmap sizes (8/16/22/32/48…):
// a request for 20 px renders the 16 px pixmap, and any scale transform on
// top resamples it into blur. The composite therefore never scales icons:
// it solves the grid geometry so every mini icon lands exactly on a stock
// size, and lets the spacing flex instead.

var STEPS = [8, 16, 22, 32, 48, 64, 96, 128, 256];

// largest stock size that fits into v
function stepDown(v) {
    var s = STEPS[0];
    for (var i = 1; i < STEPS.length; ++i) {
        if (STEPS[i] <= v) {
            s = STEPS[i];
        }
    }
    return s;
}

// Grid geometry for the composite. A stock size that fits the design cell
// (T = (width - 2*inset - gap*(cols-1)) / cols, with ~4-5% gaps and ~10%
// inset when framed) and stays at least 75% of T wins: the solver snaps to
// it and the spacing flexes — icons render 1:1. Between stock steps (e.g.
// 48 px with a 3x3 grid: 16 does not fit, 8 is far too small) the painted
// size stays at T and the loader's internal scaling is the least evil.
// Returns { size, gap, inset } with cols*size + (cols-1)*gap + 2*inset == width.
function compositeGeometry(width, cols, frame) {
    var gapMin = 2;
    var insetMin = frame ? 2 : 0;
    var gap = Math.max(gapMin, Math.round(width * (frame ? 0.04 : 0.05)));
    var inset = frame ? Math.max(insetMin, Math.round(width * 0.10)) : 0;
    var target = (width - 2 * inset - gap * (cols - 1)) / cols;
    var fitMax = (width - 2 * insetMin - gapMin * (cols - 1)) / cols;
    var s = stepDown(fitMax);
    if (s <= fitMax && s >= target * 0.75) {
        var flexGap = Math.min(gap, (width - 2 * insetMin - cols * s) / (cols - 1));
        var flexInset = (width - cols * s - (cols - 1) * flexGap) / 2;
        return { size: s, gap: flexGap, inset: flexInset };
    }
    return { size: target, gap: gap, inset: inset };
}
