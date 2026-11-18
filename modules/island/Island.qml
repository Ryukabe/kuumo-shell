import QtQuick
import QtQuick.Effects
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"
import "../clipboard"
import "../control"
import "../launcher"
import "../media"
import "../notifications"
import "../osd"
import "../power"
import "../theme"
import "../workspaces"

Item {
    id: root

    property alias pill: pill

    // Gap between the screen edge and the island, and the space the island reserves
    // for windows. Based on the idle size only, so it never changes during a morph.
    readonly property int topGap: 8
    readonly property int reservedHeight: topGap + layouts.idle.h

    // How far the moonlight halo reaches past the pill
    readonly property int haloReach: 24

    // The clock is drawn once at its largest size and scaled down, so text
    // never re-rasterizes (and never steps in whole pixels) during a morph.
    readonly property int fullClockSize: 24

    // Padding around the clock (and date) for the area you tap
    readonly property int tapPad: 6

    // Widths are even so the settled island sits on whole pixels.
    readonly property var layouts: ({
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
            // The phone's battery ring on the KDE Connect page
            phoneIconSize: 56
        },
        // Search field on top, one row per matching app below. The height is not here:
        // it grows with the number of results (see launcherLayout).
        launcher: {
            w: 436, clockSize: 12, padX: 16, padTop: 12, padBottom: 12,
            // Search field and the gap above the list
            searchH: 32, fontSize: 15, listGap: 8,
            // Result rows: at most maxRows show, then the list scrolls
            maxRows: 6, rowH: 40, rowPad: 12, iconSize: 24, iconGap: 12,
            // The emoji picker: a grid of emojiCols columns and at most emojiRows rows of
            // square cells, and a line under it with the name of the emoji you are on
            emojiCols: 9, emojiRows: 4, emojiCell: 44, emojiSize: 26, emojiCaptionH: 28
        },
        // The clipboard history: search field on top, one row per item below. The height
        // is not here either (see clipboardLayout).
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
        // The theme switcher: search row on top, a thin line, a row of theme cards, and the
        // count under it. The size is fixed: h = padTop + searchH + listGap + rowH + footerH +
        // padBottom. A card is cardW x cardH and grows by selectedScale when highlighted, so
        // rowH must fit the grown card. The dots and the name sit on a shade shadeH tall along
        // the card's bottom edge; appliedDot marks the saved theme.
        theme: {
            w: 520, h: 176, clockSize: 12, padX: 16, padTop: 12, padBottom: 8,
            searchH: 32, fontSize: 15, listGap: 8, dividerGap: 4, dividerH: 1,
            rowH: 92, footerH: 24,
            cardW: 112, cardH: 70, cardGap: 20, cardRadius: 10, cardBorder: 1, selectedScale: 1.25,
            cardPad: 8, cardTextGap: 4, shadeH: 44, dotSize: 6, dotGap: 4,
            appliedDot: 6, appliedInset: 8
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

    // A toast shows only while the island is at rest (not while a panel is open or an OSD shows)
    readonly property bool toastVisible: NotificationService.toastActive
        && IslandState.mode === "idle" && !IslandState.osdActive

    // How tall the launcher's list is: one row per result (up to maxRows), or in the emoji
    // picker the rows of emoji (up to emojiRows) plus the caption line
    readonly property int launcherListH: {
        const L = layouts.launcher
        if (LauncherService.gridView)
            return Math.min(Math.ceil(LauncherService.results.length / L.emojiCols), L.emojiRows) * L.emojiCell + L.emojiCaptionH
        return Math.min(LauncherService.results.length, L.maxRows) * L.rowH
    }

    // The launcher is as tall as its search field plus its list
    readonly property var launcherLayout: ({
        w: layouts.launcher.w,
        h: layouts.launcher.padTop + layouts.launcher.searchH + layouts.launcher.padBottom
            + (launcherListH > 0 ? layouts.launcher.listGap + launcherListH : 0),
        clockSize: layouts.launcher.clockSize
    })

    // The clipboard is as tall as its search field plus one row per item (up to maxRows).
    // It keeps one row of room when there is nothing to list, for the "nothing copied" text.
    // (Reading ClipboardService here also starts it when the shell starts.)
    readonly property int clipboardRows: Math.max(1, Math.min(ClipboardService.rows.length, layouts.clipboard.maxRows))
    readonly property var clipboardLayout: ({
        w: layouts.clipboard.w,
        h: layouts.clipboard.padTop + layouts.clipboard.searchH + layouts.clipboard.padBottom
            + layouts.clipboard.listGap + clipboardRows * layouts.clipboard.rowH,
        clockSize: layouts.clipboard.clockSize
    })

    // Reading ThemeService here starts it when the shell starts, so the saved theme is restored
    readonly property bool themeServiceStarted: ThemeService.started

    // The power menu and the theme switcher have fixed sizes, so layouts.power and
    // layouts.theme are used as they are (the mode name finds them in the last step below).
    readonly property var cur: IslandState.osdActive
        ? layouts.osd
        : toastVisible
            ? layouts.toast
            : IslandState.launcher
                ? launcherLayout
                : IslandState.clipboard
                    ? clipboardLayout
                    : (layouts[IslandState.mode] ?? layouts.idle)

    readonly property real idleScale: layouts.idle.clockSize / fullClockSize
    readonly property real extClockScale: layouts.extended.clockSize / fullClockSize
    readonly property real ctlClockScale: layouts.control.clockSize / fullClockSize

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }

    // The clock fades out during an OSD, a toast, the launcher, the clipboard, the power menu
    // or the theme switcher, and on the control center's other pages (Wi-Fi list, Night
    // Light, KDE Connect, notifications); it only shows on the main page
    readonly property bool clockHidden: IslandState.osdActive || toastVisible
        || IslandState.launcher || IslandState.clipboard || IslandState.power || IslandState.theme
        || (IslandState.control && controlView.page !== "main")

    // Height of the clock + date block when extended, used to center it vertically
    readonly property real clockBlockH:
        clock.implicitHeight * extClockScale
        + layouts.extended.dateGap + dateText.implicitHeight

    // Where the clock sits inside the pill, per mode. During the OSD it stays where
    // its mode put it and simply fades out.
    readonly property real clockX: IslandState.extended
        ? layouts.extended.padX
        : IslandState.control
            ? layouts.control.padX
            : (layouts.idle.w - clock.implicitWidth * idleScale) / 2
    readonly property real clockY: IslandState.extended
        ? (layouts.extended.h - clockBlockH) / 2
        : IslandState.control
            ? layouts.control.clockCenterY - clock.implicitHeight * ctlClockScale / 2
            : (layouts.idle.h - clock.implicitHeight * idleScale) / 2

    // The area you tap: around the clock and date when extended (opens the control
    // center), around the small clock when in the control center (goes back)
    readonly property rect extTap: Qt.rect(
        layouts.extended.padX - tapPad,
        (layouts.extended.h - clockBlockH) / 2 - tapPad,
        Math.max(clock.implicitWidth * extClockScale, dateText.implicitWidth) + 2 * tapPad,
        clockBlockH + 2 * tapPad)
    readonly property rect ctlTap: Qt.rect(
        layouts.control.padX - tapPad,
        layouts.control.clockCenterY - clock.implicitHeight * ctlClockScale / 2 - tapPad,
        clock.implicitWidth * ctlClockScale + 2 * tapPad,
        clock.implicitHeight * ctlClockScale + 2 * tapPad)
    readonly property rect tapRect: IslandState.control ? ctlTap : extTap

    // The right column (music, divider, workspace dots) is centered as one block
    readonly property real rightColH: media.height + layouts.extended.dotsGap + dots.height
    readonly property real rightColY: Math.round((layouts.extended.h - rightColH) / 2)

    // One spring preset for everything that morphs, so the island and the clock
    // start and finish together
    component Follow: Spring {
        response: Motion.morph.response
        dampingFraction: Motion.morph.damping
        animated: !ShellState.motionReduced
    }

    Follow { id: sw; target: root.cur.w }
    Follow { id: sh; target: root.cur.h }
    Follow { id: sx; target: root.clockX }
    Follow { id: sy; target: root.clockY }
    Follow { id: ss; target: root.cur.clockSize }

    // Start at rest, not mid-spring, once all targets are known
    Component.onCompleted: {
        sw.snap(); sh.snap(); sx.snap(); sy.snap(); ss.snap()
    }

    // How far the pill has grown from idle to extended (0..1), read from the width
    // spring so everything that fades in stays in step with the morph
    readonly property real growth: clamp01(
        (sw.value - layouts.idle.w) / (layouts.extended.w - layouts.idle.w))

    // The extended content appears over the later part of the growth
    readonly property real revealed: clamp01(
        (growth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))

    // Leaving extended (collapse, control center or an OSD) hides it fast
    property real shown: IslandState.extended && !IslandState.osdActive ? 1 : 0
    Behavior on shown {
        NumberAnimation {
            duration: root.shown > 0 || IslandState.osdActive || !IslandState.extended ? Motion.fadeOut : 0
            easing.type: Easing.OutCubic
        }
    }

    readonly property real reveal: revealed * shown

    // The OSD content appears the same way, measured against the OSD's own size
    readonly property real osdGrowth: clamp01(
        (sw.value - layouts.idle.w) / (layouts.osd.w - layouts.idle.w))
    readonly property real osdRevealed: clamp01(
        (osdGrowth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))
    property real osdShown: IslandState.osdActive ? 1 : 0
    Behavior on osdShown {
        NumberAnimation {
            duration: IslandState.osdActive ? 0 : Motion.fadeOut
            easing.type: Easing.OutCubic
        }
    }
    readonly property real osdReveal: osdRevealed * osdShown

    // The toast content appears the same way, measured against the toast's own size
    readonly property real toastGrowth: clamp01(
        (sw.value - layouts.idle.w) / (layouts.toast.w - layouts.idle.w))
    readonly property real toastRevealed: clamp01(
        (toastGrowth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))
    property real toastShown: toastVisible ? 1 : 0
    Behavior on toastShown {
        NumberAnimation {
            duration: root.toastVisible ? 0 : Motion.fadeOut
            easing.type: Easing.OutCubic
        }
    }
    readonly property real toastReveal: toastRevealed * toastShown

    // The control center content appears the same way. It is measured by height,
    // from the extended height to the control height, because the control center
    // always opens from the extended panel (the width barely changes).
    readonly property real ctlGrowth: clamp01(
        (sh.value - layouts.extended.h) / (layouts.control.h - layouts.extended.h))
    readonly property real ctlRevealed: clamp01(
        (ctlGrowth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))

    // Leaving the control center (going back or an OSD) hides it fast
    property real ctlShown: IslandState.control && !IslandState.osdActive ? 1 : 0
    Behavior on ctlShown {
        NumberAnimation {
            duration: root.ctlShown > 0 || IslandState.osdActive || !IslandState.control ? Motion.fadeOut : 0
            easing.type: Easing.OutCubic
        }
    }
    readonly property real ctlReveal: ctlRevealed * ctlShown

    // The launcher content appears measured by width, from idle to the launcher width.
    // Its height changes with the results, so height would make it flicker while typing.
    readonly property real launcherGrowth: clamp01(
        (sw.value - layouts.idle.w) / (layouts.launcher.w - layouts.idle.w))
    readonly property real launcherRevealed: clamp01(
        (launcherGrowth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))

    // Leaving the launcher (closing or an OSD) hides it fast
    property real launcherShown: IslandState.launcher && !IslandState.osdActive ? 1 : 0
    Behavior on launcherShown {
        NumberAnimation {
            duration: root.launcherShown > 0 || IslandState.osdActive || !IslandState.launcher ? Motion.fadeOut : 0
            easing.type: Easing.OutCubic
        }
    }
    readonly property real launcherReveal: launcherRevealed * launcherShown

    // The clipboard content appears the same way as the launcher's, measured by width
    readonly property real clipboardGrowth: clamp01(
        (sw.value - layouts.idle.w) / (layouts.clipboard.w - layouts.idle.w))
    readonly property real clipboardRevealed: clamp01(
        (clipboardGrowth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))

    // Leaving the clipboard (closing or an OSD) hides it fast
    property real clipboardShown: IslandState.clipboard && !IslandState.osdActive ? 1 : 0
    Behavior on clipboardShown {
        NumberAnimation {
            duration: root.clipboardShown > 0 || IslandState.osdActive || !IslandState.clipboard ? Motion.fadeOut : 0
            easing.type: Easing.OutCubic
        }
    }
    readonly property real clipboardReveal: clipboardRevealed * clipboardShown

    // The power menu content appears the same way, measured by width
    readonly property real powerGrowth: clamp01(
        (sw.value - layouts.idle.w) / (layouts.power.w - layouts.idle.w))
    readonly property real powerRevealed: clamp01(
        (powerGrowth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))

    // Leaving the power menu (closing or an OSD) hides it fast
    property real powerShown: IslandState.power && !IslandState.osdActive ? 1 : 0
    Behavior on powerShown {
        NumberAnimation {
            duration: root.powerShown > 0 || IslandState.osdActive || !IslandState.power ? Motion.fadeOut : 0
            easing.type: Easing.OutCubic
        }
    }
    readonly property real powerReveal: powerRevealed * powerShown

    // The theme switcher content appears the same way, measured by width
    readonly property real themeGrowth: clamp01(
        (sw.value - layouts.idle.w) / (layouts.theme.w - layouts.idle.w))
    readonly property real themeRevealed: clamp01(
        (themeGrowth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))

    // Leaving the theme switcher (closing or an OSD) hides it fast
    property real themeShown: IslandState.theme && !IslandState.osdActive ? 1 : 0
    Behavior on themeShown {
        NumberAnimation {
            duration: root.themeShown > 0 || IslandState.osdActive || !IslandState.theme ? Motion.fadeOut : 0
            easing.type: Easing.OutCubic
        }
    }
    readonly property real themeReveal: themeRevealed * themeShown

    // ── Opening and closing by hover ──
    // Hovering the island opens the extended panel after a short delay; leaving it closes
    // the panel after a slightly longer one. Only the extended panel closes this way: the
    // control center, the launcher, the clipboard, the power menu and the theme switcher stay
    // until you click outside or press ESC. While a toast shows, hovering keeps the toast
    // instead of opening the panel.
    Timer {
        id: openTimer
        interval: Root.Config.islandHoverOpenMs
        onTriggered: if (pillHover.hovered && IslandState.mode === "idle" && !root.toastVisible) IslandState.expand()
    }

    Timer {
        id: closeTimer
        interval: Root.Config.islandHoverCloseMs
        onTriggered: if (!pillHover.hovered && IslandState.extended) IslandState.collapse()
    }

    // ── Moonlight halo ──
    // The pill clips its children, so the halo sits behind it as a sibling. The
    // source has the pill's own color and shape and is hidden by the pill itself;
    // only its blurred light shadow shows around the edge. During the OSD it
    // brightens with the level.
    property real haloBoost: IslandState.osdActive ? Theme.haloOsdBoost * OsdService.haloLevel : 0
    Behavior on haloBoost {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: haloSource
        visible: false
        layer.enabled: true
        x: pill.x
        y: pill.y
        width: pill.width
        height: pill.height
        radius: pill.radius
        color: Theme.bg
    }

    MultiEffect {
        visible: Root.Config.islandHalo
        x: haloSource.x
        y: haloSource.y
        width: haloSource.width
        height: haloSource.height
        source: haloSource
        blurMax: root.haloReach
        shadowEnabled: true
        shadowColor: Theme.fg
        shadowOpacity: Theme.haloOpacity + root.haloBoost
        shadowBlur: 1.0
    }

    IslandPill {
        id: pill

        // No rounding: the spring moves in fractions of a pixel and the GPU draws
        // that smoothly. Rounding made the settle step in whole pixels.
        width: Math.max(sw.value, 20)
        height: Math.max(sh.value, 12)
        x: (root.width - width) / 2
        y: root.topGap

        // Watches the pointer over the whole pill (children included): opens and closes
        // by hover, and keeps a toast open while the pointer is on it
        HoverHandler {
            id: pillHover
            onHoveredChanged: {
                NotificationService.toastHeld = hovered
                if (hovered) {
                    closeTimer.stop()
                    if (IslandState.mode === "idle" && !root.toastVisible) openTimer.restart()
                } else {
                    openTimer.stop()
                    if (IslandState.extended) closeTimer.restart()
                }
            }
        }

        // Hover highlight behind the clock: shows that it can be tapped
        Rectangle {
            x: root.tapRect.x
            y: root.tapRect.y
            width: root.tapRect.width
            height: root.tapRect.height
            radius: Theme.radiusSmall
            color: Theme.subBg
            opacity: tapArea.containsMouse ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
            }
        }

        // The one shared clock: it moves and scales, it is never swapped. It fades out
        // during an OSD, a toast, the launcher, the clipboard, the power menu or the theme
        // switcher, and on the control center's other pages.
        NumberFlow {
            id: clock
            weight: Font.Bold
            x: sx.value
            y: sy.value
            text: SystemState.timeText
            // Hour tens 0-2, minute tens 0-5, everything else 0-9 (index 2 is the colon)
            rings: [3, 10, 10, 6, 10]
            pixelSize: root.fullClockSize
            animated: !ShellState.motionReduced
            transformOrigin: Item.TopLeft
            scale: ss.value / root.fullClockSize
            opacity: root.clockHidden ? 0 : 1
            Behavior on opacity {
                NumberAnimation {
                    duration: root.clockHidden ? Motion.fadeOut : Motion.fadeIn
                    easing.type: Easing.OutCubic
                }
            }
            layer.enabled: true
            layer.smooth: true
        }

        Text {
            id: dateText
            x: sx.value
            y: sy.value + clock.implicitHeight * clock.scale + root.layouts.extended.dateGap
            text: SystemState.dateText
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeXs
            opacity: root.reveal
        }

        // Takes clicks on the empty parts of the pill and does nothing with them. If nothing
        // took them, they would fall through to the click-anywhere layer behind the island
        // and close everything.
        MouseArea {
            anchors.fill: parent
        }

        // Tap the clock: extended opens the control center, the control center goes back.
        // Not on the control center's other pages, where the clock is hidden.
        MouseArea {
            id: tapArea
            x: root.tapRect.x
            y: root.tapRect.y
            width: root.tapRect.width
            height: root.tapRect.height
            enabled: !IslandState.osdActive
                && (IslandState.control
                    ? controlView.page === "main"
                    : IslandState.extended && root.reveal > 0.5)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: IslandState.control ? IslandState.backToExtended() : IslandState.openControl()
        }

        // Declared after the MouseAreas so the art's play/pause click, the dots and the
        // scroll handler sit on top. They follow the pill's right edge.
        MediaView {
            id: media
            layout: root.layouts.extended
            reveal: root.reveal
            anchors.right: parent.right
            anchors.rightMargin: root.layouts.extended.padX
            y: root.rightColY
        }

        WorkspaceDots {
            id: dots
            layout: root.layouts.extended
            reveal: root.reveal
            anchors.right: parent.right
            anchors.rightMargin: root.layouts.extended.padX
            y: root.rightColY + media.height + root.layouts.extended.dotsGap
        }

        // Control center content (buttons, sliders, other pages). It starts at pageTop;
        // the main page moves itself down to make room for the clock.
        // Declared after the MouseAreas so taps and drags reach it.
        ControlView {
            id: controlView
            layout: root.layouts.control
            reveal: root.ctlReveal
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.layouts.control.pageTop
        }

        // Launcher: search field and the list (or the emoji grid), as tall as the island
        LauncherView {
            layout: root.layouts.launcher
            reveal: root.launcherReveal
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.layouts.launcher.w
            height: root.launcherLayout.h
        }

        // Clipboard: search field and the history list, as tall as the island
        ClipboardView {
            layout: root.layouts.clipboard
            reveal: root.clipboardReveal
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.layouts.clipboard.w
            height: root.clipboardLayout.h
        }

        // Power menu: one row of round buttons, as tall as the island
        PowerView {
            layout: root.layouts.power
            reveal: root.powerReveal
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.layouts.power.w
            height: root.layouts.power.h
        }

        // Theme switcher: search pill and a row of theme cards, as tall as the island
        ThemeView {
            layout: root.layouts.theme
            reveal: root.themeReveal
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.layouts.theme.w
            height: root.layouts.theme.h
        }

        // A notification, centered in the pill
        ToastView {
            layout: root.layouts.toast
            reveal: root.toastReveal
            anchors.centerIn: parent
        }

        // Volume / brightness, centered in the pill
        OsdView {
            layout: root.layouts.osd
            reveal: root.osdReveal
            anchors.centerIn: parent
        }
    }
}