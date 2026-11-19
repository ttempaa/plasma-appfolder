.pragma library

// Returns the side the popup should open to: "up", "down", "left",
// "right". Distances are fractions of the screen size from the widget to
// each edge; the preferred side wins unless it is worse than the nearest
// edge by more than the factor k (0 = strictly nearest edge wins).
function pickSide(nTop, nBottom, nLeft, nRight, pref, k) {
    const sides = [
        ["up", nBottom],
        ["down", nTop],
        ["left", nRight],
        ["right", nLeft]
    ];

    let nearest = sides[0];
    for (let i = 1; i < sides.length; ++i) {
        if (sides[i][1] < nearest[1]) {
            nearest = sides[i];
        }
    }

    for (let i = 0; i < sides.length; ++i) {
        if (sides[i][0] === pref && sides[i][1] <= nearest[1] * (1 + k)) {
            return pref;
        }
    }
    return nearest[0];
}

// Popup position for the chosen side: centered along the anchor edge and
// offset by the gap, then clamped into the work area. Plain-map arguments
// keep the function testable outside a running plasmoid; returns {x, y}
// rounded to whole pixels.
function popupRect(side, anchorRect, popupSize, margins, gap, screenSize) {
    let x;
    let y;
    if (side === "up") {
        x = anchorRect.x + anchorRect.width / 2 - popupSize.width / 2;
        y = anchorRect.y - popupSize.height - gap;
    } else if (side === "down") {
        x = anchorRect.x + anchorRect.width / 2 - popupSize.width / 2;
        y = anchorRect.y + anchorRect.height + gap;
    } else if (side === "left") {
        x = anchorRect.x - popupSize.width - gap;
        y = anchorRect.y + anchorRect.height / 2 - popupSize.height / 2;
    } else {
        x = anchorRect.x + anchorRect.width + gap;
        y = anchorRect.y + anchorRect.height / 2 - popupSize.height / 2;
    }

    const minX = margins.left + gap;
    const maxX = Math.max(minX, screenSize.width - margins.right - popupSize.width - gap);
    const minY = margins.top + gap;
    const maxY = Math.max(minY, screenSize.height - margins.bottom - popupSize.height - gap);
    return {
        x: Math.round(Math.max(minX, Math.min(x, maxX))),
        y: Math.round(Math.max(minY, Math.min(y, maxY)))
    };
}
