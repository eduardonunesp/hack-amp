package main

// Header-only window dragging for Linux (X11). On a left press inside the
// header strip we send a _NET_WM_MOVERESIZE client message to the root
// window: the window manager then runs the drag natively (with snapping).
// Only compiled on Linux (file suffix), so no import guards needed here.
// NOTE: Wayland does not support this message; the drag is a no-op there.

import xlib "vendor:x11/xlib"
import rl "vendor:raylib"

// EWMH: _NET_WM_MOVERESIZE direction and source constants.
_NET_WM_MOVERESIZE_MOVE          :: 8
_NET_WM_MOVERESIZE_SOURCE_APP    :: 1
_NET_WM_MOVERESIZE_BUTTON_NONE   :: 0

win_drag :: proc() {
	if !rl.IsMouseButtonPressed(.LEFT) {
		return
	}
	if rl.GetMousePosition().y > HEADER_DRAG_H {
		return
	}

	display := xlib.OpenDisplay(nil)
	if display == nil {
		return
	}
	defer xlib.CloseDisplay(display)

	root := xlib.DefaultRootWindow(display)
	x11_window := xlib.Window(uintptr(rl.GetWindowHandle()))

	// Cursor position in root-window (screen) coordinates.
	root_x, root_y : i32
	xlib.QueryPointer(display, root, nil, nil, &root_x, &root_y, nil, nil, nil)

	atom := xlib.InternAtom(display, "_NET_WM_MOVERESIZE", false)

	event := xlib.XEvent{}
	event.type = xlib.EventType.ClientMessage
	event.xclient = xlib.XClientMessageEvent {
		display      = display,
		window       = x11_window,
		message_type = atom,
		format       = 32,
		data = {
			l = {
				int(root_x),
				int(root_y),
				_NET_WM_MOVERESIZE_MOVE,
				_NET_WM_MOVERESIZE_BUTTON_NONE,
				_NET_WM_MOVERESIZE_SOURCE_APP,
			},
		},
	}

	xlib.SendEvent(
		display,
		root,
		false,
		xlib.EventMask{.SubstructureNotify, .SubstructureRedirect},
		&event,
	)
	xlib.Flush(display)
}
