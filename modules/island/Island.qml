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
import "../polkit"
import "../power"
import "../theme"
import "../wallpaper"
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

    // The sizes of every mode are in IslandLayouts.qml
    readonly property var layouts: IslandLayouts.all

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

    // Reading the theme and wallpaper services here starts them when the shell starts, so the
    // saved theme and wallpaper are restored at startup
    readonly property bool themeServiceStarted: ThemeService.started
    readonly property bool wallpaperServiceStarted: WallpaperService.started

    // Same for the polkit service: it registers the polkit agent when the shell starts, so a
    // request can open the prompt at any time
    readonly property bool polkitServiceStarted: PolkitService.started

    // The power menu, the polkit prompt and the two switchers have fixed sizes, so layouts.power,
    // layouts.polkit, layouts.theme and layouts.wallpaper are used as they are (the mode name
    // finds them in the last step below).
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

    // In a switcher the clock sits at the top left, like in the control center
    readonly property bool inSwitcher: IslandState.theme || IslandState.wallpaper
    readonly property var switcherLayout: IslandState.wallpaper ? layouts.wallpaper : layouts.theme
    readonly property real swClockScale: switcherLayout.clockSize / fullClockSize

    // The clock fades out during an OSD, a toast, the launcher, the clipboard, the power
    // menu and the polkit prompt, and on the control center's other pages (Wi-Fi list, Night
    // Light, KDE Connect, notifications); it shows on the control center's main page and in
    // the two switchers
    readonly property bool clockHidden: IslandState.osdActive || toastVisible
        || IslandState.launcher || IslandState.clipboard || IslandState.power
        || IslandState.polkit
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
            : inSwitcher
                ? switcherLayout.padX
                : (layouts.idle.w - clock.implicitWidth * idleScale) / 2
    readonly property real clockY: IslandState.extended
        ? (layouts.extended.h - clockBlockH) / 2
        : IslandState.control
            ? layouts.control.clockCenterY - clock.implicitHeight * ctlClockScale / 2
            : inSwitcher
                ? switcherLayout.clockCenterY - clock.implicitHeight * swClockScale / 2
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

    // ── How far each mode's content has appeared (see Reveal.qml) ──
    // Most are measured by width, from idle to the mode's own width. The control center is
    // measured by height, from the extended height, because it always opens from the extended
    // panel (the width barely changes). The launcher and clipboard heights change with their
    // results, so height would make them flicker while typing. The OSD and the toast do not
    // give way to an OSD.
    Reveal { id: extendedFade;  current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.extended.w;  active: IslandState.extended }
    Reveal { id: controlFade;   current: sh.value; startSize: root.layouts.extended.h; endSize: root.layouts.control.h;   active: IslandState.control }
    Reveal { id: launcherFade;  current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.launcher.w;  active: IslandState.launcher }
    Reveal { id: clipboardFade; current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.clipboard.w; active: IslandState.clipboard }
    Reveal { id: powerFade;     current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.power.w;     active: IslandState.power }
    Reveal { id: polkitFade;    current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.polkit.w;    active: IslandState.polkit }
    Reveal { id: themeFade;     current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.theme.w;     active: IslandState.theme }
    Reveal { id: wallpaperFade; current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.wallpaper.w; active: IslandState.wallpaper }
    Reveal { id: osdFade;       current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.osd.w;       active: IslandState.osdActive; hideOnOsd: false }
    Reveal { id: toastFade;     current: sw.value; startSize: root.layouts.idle.w;     endSize: root.layouts.toast.w;     active: root.toastVisible;         hideOnOsd: false }
    
    // The numbers the views take as their `reveal`
    readonly property real reveal: extendedFade.value
    readonly property real ctlReveal: controlFade.value
    readonly property real launcherReveal: launcherFade.value
    readonly property real clipboardReveal: clipboardFade.value
    readonly property real powerReveal: powerFade.value
    readonly property real polkitReveal: polkitFade.value
    readonly property real themeReveal: themeFade.value
    readonly property real wallpaperReveal: wallpaperFade.value
    readonly property real osdReveal: osdFade.value
    readonly property real toastReveal: toastFade.value

    // ── Opening and closing by hover ──
    // Hovering the island opens the extended panel after a short delay; leaving it closes
    // the panel after a slightly longer one. Only the extended panel closes this way: the
    // control center, the launcher, the clipboard, the power menu, the polkit prompt and the
    // switchers stay until you click outside or press ESC. While a toast shows, hovering
    // keeps the toast instead of opening the panel.
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

        DropArea {
            id: wallpaperDrop
            anchors.fill: parent

            // The right half of the island adds to every theme (when that is on in Settings)
            readonly property bool allThemes: Root.Config.wallpaperDropAllThemes && drag.x > width / 2

            // Resting on the pill opens the switcher, so dragging past it by accident does nothing
            Timer {
                id: dwell
                interval: Root.Config.wallpaperDropOpenMs
                onTriggered: if (wallpaperDrop.containsDrag && !IslandState.wallpaper) IslandState.openWallpaper()
            }

            onEntered: drag => {
                if (!Root.Config.wallpaperDropEnabled || !WallpaperService.hasImages(drag.urls)) {
                    drag.accepted = false
                    return
                }
                drag.accepted = true
                if (IslandState.wallpaper) return
                if (Root.Config.wallpaperDropOpenMs <= 0) IslandState.openWallpaper()
                else dwell.restart()
            }
            onExited: dwell.stop()
            onDropped: drop => {
                dwell.stop()
                // Always a copy, so the file manager never removes the original. A drop on the
                // closed pill adds to the current theme; the halves only exist once it is open.
                drop.accept(Qt.CopyAction)
                WallpaperService.addFiles(drop.urls,
                    IslandState.wallpaper && Root.Config.wallpaperDropAllThemes && drop.x > wallpaperDrop.width / 2)
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

        // The one shared clock: it moves and scales, it is never swapped. Only the digits that
        // change roll (ClockText). It fades out during an OSD, a toast, the launcher, the
        // clipboard, the power menu and the polkit prompt, and on the control center's other
        // pages. In the two switchers it sits at the top left.
        ClockText {
            id: clock
            weight: Font.Bold
            x: sx.value
            y: sy.value
            text: SystemState.timeText
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

        // Polkit prompt: the message, the password field with the Authenticate button inside
        // it, and the wrong-password line, as tall as the island
        PolkitView {
            layout: root.layouts.polkit
            reveal: root.polkitReveal
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.layouts.polkit.w
            height: root.layouts.polkit.h
        }

        // Theme switcher: the name and search pill on top, a row of theme cards, as tall as
        // the island (the clock above it is the shared one)
        ThemeView {
            layout: root.layouts.theme
            reveal: root.themeReveal
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.layouts.theme.w
            height: root.layouts.theme.h
        }

        // Wallpaper switcher: the name, Static / Animated switch and search pill on top, a row
        // of wallpaper cards, as tall as the island
        WallpaperView {
            layout: root.layouts.wallpaper
            reveal: root.wallpaperReveal
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.layouts.wallpaper.w
            height: root.layouts.wallpaper.h
            dropping: wallpaperDrop.containsDrag
            dropRight: wallpaperDrop.allThemes
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