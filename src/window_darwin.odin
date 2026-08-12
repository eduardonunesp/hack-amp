package main

// Header-only window dragging for macOS. On a left press inside the header
// strip we hand the OS the current mouse-down event via
// performWindowDragWithEvent: — the OS then runs its native drag loop
// (smooth, with edge snapping). Polling SetWindowPosition every frame is
// laggy and jittery on macOS, so we never do that.
// Only compiled on Darwin (file suffix), so no import guards needed here.

import F "core:sys/darwin/Foundation"
import rl "vendor:raylib"

win_drag :: proc() {
	if !rl.IsMouseButtonPressed(.LEFT) {
		return
	}
	if rl.GetMousePosition().y > HEADER_DRAG_H {
		return
	}

	app := F.Application_sharedApplication()
	event := F.Application_currentEvent(app)
	if event == nil {
		return
	}

	ns_window := (^F.Window)(rl.GetWindowHandle())
	F.Window_performWindowDragWithEvent(ns_window, event)
}
