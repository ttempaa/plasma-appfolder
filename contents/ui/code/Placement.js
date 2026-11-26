.pragma library

// Returns the side the popup should open to: "up", "down", "left" or
// "right". freeUp/freeDown/freeLeft/freeRight: free work area in each
// direction as a fraction of it. A side is scored by the free space
// opposite to it, so the lowest score is the roomiest side; the preferred
// side wins unless its score is worse than the lowest one by more than the
// tolerance (0 = the preferred side wins ties only).
function pickSide(freeUp, freeDown, freeLeft, freeRight, preferred, tolerance) {
    const sides = [
        ["up", freeDown],
        ["down", freeUp],
        ["left", freeRight],
        ["right", freeLeft]
    ];

    let nearest = sides[0];
    for (let i = 1; i < sides.length; ++i) {
        if (sides[i][1] < nearest[1]) {
            nearest = sides[i];
        }
    }

    for (let i = 0; i < sides.length; ++i) {
        if (sides[i][0] === preferred && sides[i][1] <= nearest[1] * (1 + tolerance)) {
            return preferred;
        }
    }
    return nearest[0];
}

// Popup position for the chosen side: centered along the anchor edge and
// offset by the gap, then clamped into the work area. Plain-map arguments
// keep the function testable outside a running plasmoid; returns {x, y}
// rounded to whole pixels.
function popupPosition(side, anchorRect, popupSize, screenMargins, gap, screenSize) {
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

    const minX = screenMargins.left + gap;
    const maxX = Math.max(minX, screenSize.width - screenMargins.right - popupSize.width - gap);
    const minY = screenMargins.top + gap;
    const maxY = Math.max(minY, screenSize.height - screenMargins.bottom - popupSize.height - gap);
    return {
        x: Math.round(Math.max(minX, Math.min(x, maxX))),
        y: Math.round(Math.max(minY, Math.min(y, maxY)))
    };
}
