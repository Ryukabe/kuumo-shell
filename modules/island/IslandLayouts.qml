pragma Singleton

import QtQuick
import Quickshell
import "../.." as Root

// The sizes of every mode of the island. Island.qml reads them as IslandLayouts.all.
// Widths are even so the settled island sits on whole pixels.
Singleton {
    readonly property var all: ({
        idle:     { w: 124, h: 32,  clockSize: 12 },
        extended: {
            w: 436, h: 100, clockSize: 24, padX: 22, dateGap: 2,
            // Music side: art on the right, track info to its left, divider below
            mediaW: 190, artSize: 32, artGap: 10, artRadius: 6, iconSize: 12,
            textSlide: 8,
            dividerGap: 12, dividerH: 2, dividerGlow: 12,
            // Workspace dots under the divider
            dotsGap: 8, dotSize: 6, dotActiveW: 16, dotGap: 6, dotHit: 4
        },
        control: {
            w: 312, h: 380, clockSize: 12, padX: 16,
            // clockCenterY: how far below the top edge the small clock's middle sits
            clockCenterY: 16,
            // Content of the main page: below the clock, first a row of round buttons,
            // then the sliders, then the notifications card. contentBottom is the space
            // kept free under any page.
            contentTop: 48, contentBottom: 16, sectionGap: 20,
            // The other pages (Wi-Fi list, Night Light, KDE Connect, notifications) have no
            // clock, so they start higher
            pageTop: 12,
            // Round buttons: one slot each, side by side, label underneath
            tileSlots: 4, btnSize: 52, btnBorder: 1, btnGlowReach: 16, tileIconSize: 24, labelGap: 6,
            // Slider rows (volume, brightness): icon, bar with a moon at the end of its fill,
            // percentage on the right
            rowH: 32, rowGap: 12,
            iconSize: 20, iconGap: 12, barH: 4, dotSize: 8, glowReach: 14,
            pctW: 40, pctGap: 12,
            // Changing page: how far the pages slide while fading
            pageSlide: 14,
            // The page header, then (Wi-Fi list) one row per network
            headerH: 32, headerIconSize: 20,
            netRowH: 48, netRowGap: 4, netPad: 12, netIconSize: 20, netIconGap: 12, netLockSize: 14,
            // The buttons and password field that open under a network (also the action
            // buttons of the KDE Connect page)
            netActionH: 28, netActionGap: 8, netActionPad: 14,
            // The notifications card (bell, pulsing dot) and the rows of the notifications list
            cardH: 64, cardIconSize: 24, bellDot: 8,
            noteRowH: 64, noteIconSize: 36, noteIconGap: 12, noteIconRadius: 8, noteCloseSize: 18,
            // The KDE Connect page: a card with the phone icon (a battery ring around it) on
            // the left and the percentage, status and connection on the right, then a row of
            // round buttons and a card that opens the KDE Connect app
            phoneIconSize: 80, phoneCardH: 108, phoneCardPad: 14, phoneCardRadius: 16, phonePctSize: 28,
            signalBarW: 3, signalBarGap: 2, signalBarH: 12,
            phoneChipH: 22, phoneChipPad: 8, dropH: 32
        },
        // Search field on top, one row per matching app below. The height is not here:
        // it grows with the number of results (see launcherLayout in Island.qml).
        launcher: {
            w: 436, clockSize: 12, padX: 16, padTop: 12, padBottom: 12,
            // Search field and the gap above the list
            searchH: 32, fontSize: 15, listGap: 8,
            // Result rows: at most maxRows show (a setting), then the list scrolls
            maxRows: Root.Config.launcherMaxRows, rowH: 40, rowPad: 12, iconSize: 24, iconGap: 12,
            // The small section titles ("Apps", "Files", ...) between the groups of results
            headerH: 28,
            // The emoji picker: a grid of emojiCols columns and at most emojiRows rows of
            // square cells, and a line under it with the name of the emoji you are on
            emojiCols: 9, emojiRows: 4, emojiCell: 44, emojiSize: 26, emojiCaptionH: 28
        },
        // The clipboard history: search field on top, one row per item below. The height
        // is not here either (see clipboardLayout in Island.qml).
        clipboard: {
            w: 436, clockSize: 12, padX: 16, padTop: 12, padBottom: 12,
            searchH: 32, fontSize: 15, listGap: 8,
            // Rows: at most maxRows show, then the list scrolls. A row has a square on the
            // left (the picture of an image, else an icon), the preview of up to previewLines
            // lines with the size and age under it, and the pin and delete buttons on the right.
            maxRows: 5, rowH: 60, rowPad: 12, thumb: 40, iconSize: 24, iconGap: 12,
            previewFont: 13, previewLines: 2, actionSize: 20, actionGap: 8
        },
        // The power menu: one row of round buttons, `slots` of them across the width, each
        // with its label underneath. h = padTop + btnSize + labelGap + the label's height
        // (about 14) + padBottom. The ring of a hold button is holdRingW wide.
        power: {
            w: 436, h: 112, clockSize: 12, padX: 22, padTop: 20,
            slots: 5, btnSize: 52, btnBorder: 1, btnGlowReach: 16, tileIconSize: 24, labelGap: 6,
            holdRingW: 3
        },
        // The polkit prompt, top to bottom: a header row (round icon and title on the left,
        // the user pill in the right corner), the message (up to two lines), the password
        // field, and a line for a wrong password. The size is fixed:
        // h = padTop + headH + msgGap + msgH + fieldGap + fieldH + errorGap + errorH + padBottom.
        //  - Header: the icon ring is headH wide and tall; the pill is pillH tall, with pillPad
        //    at its sides and pillGap between its icon and the name.
        //  - Field: fieldGap is the space above it; inside it a lock icon (caps lock symbol
        //    while caps lock is on), the password, and at the right the Authenticate button,
        //    authW wide once you type, btnInset away from the field's edge. innerGap is the
        //    space between those parts. ringW is the line width of the rings and the border.
        polkit: {
            w: 400, h: 186, clockSize: 12, padX: 20, padTop: 18, padBottom: 16,
            headH: 30, iconSize: 16, iconGap: 10, ringW: 1,
            pillH: 26, pillPad: 10, pillGap: 6, pillIconSize: 14,
            msgGap: 10, msgH: 40,
            fieldGap: 14, fieldH: 40, fieldPad: 12, innerGap: 10, capsSize: 16,
            authW: 32, btnInset: 4, btnIconSize: 16,
            errorGap: 4, errorH: 14
        },
        // The theme switcher: a top row, a row of theme cards, and the count under it. The size
        // is fixed: h = padTop + searchH + listGap + rowH + footerH + padBottom.
        //  - Top row: the island's clock at the far left (clockCenterY = padTop + searchH / 2 is
        //    where its middle sits, clockSlotW the room kept for it), then the theme name, and in
        //    the right corner the search pill: searchH wide closed, searchExpandedW open, pulling
        //    out to the left. gap is the space between the items of the row.
        //  - Cards: cardW x cardH, growing by selectedScale when highlighted (keep both whole
        //    pixels). rowH = the grown card plus 8 above and below it, so the row's clip never
        //    touches a card. The dots and the name sit on a shade shadeH tall along the card's
        //    bottom edge; appliedDot marks the saved theme.
        theme: {
            w: 600, h: 200, clockSize: 12, padX: 16, padTop: 12, padBottom: 8,
            clockCenterY: 28, clockSlotW: 44, gap: 10,
            searchH: 32, searchExpandedW: 220, fontSize: 15, listGap: 8,
            rowH: 116, footerH: 24,
            cardW: 128, cardH: 80, cardGap: 24, cardRadius: 12, cardBorder: 1, selectedScale: 1.25,
            cardPad: 10, cardTextGap: 5, shadeH: 52, dotSize: 7, dotGap: 5,
            appliedDot: 7, appliedInset: 10
        },
        // The wallpaper switcher: the same island as the theme switcher (see there), plus the
        // Static / Animated switch between the theme name and the pill: toggleW x toggleH, its
        // highlight toggleInset inside it. The cards show only their name (no dots).
        wallpaper: {
            w: 600, h: 200, clockSize: 12, padX: 16, padTop: 12, padBottom: 8,
            clockCenterY: 28, clockSlotW: 44, gap: 10,
            searchH: 32, searchExpandedW: 220, fontSize: 15, listGap: 8,
            rowH: 116, footerH: 24,
            cardW: 128, cardH: 80, cardGap: 24, cardRadius: 12, cardBorder: 1, selectedScale: 1.25,
            cardPad: 10, shadeH: 52, appliedDot: 7, appliedInset: 10,
            toggleW: 148, toggleH: 26, toggleInset: 3
        },
        // Volume / brightness: icon on the left, bar with a moon at the end of its fill
        osd: {
            w: 240, h: 44, clockSize: 12, padX: 16,
            iconSize: 20, iconGap: 12, barH: 4, dotSize: 8, glowReach: 14
        },
        // A notification: app icon on the left, then app name, title and the first line of the text
        toast: {
            w: 380, h: 80, clockSize: 12, padX: 16,
            iconSize: 36, iconRadius: 8, iconGap: 12
        }
    })
}