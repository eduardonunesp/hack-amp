package main

// Header-only window dragging for macOS. On a left press inside the header
// strip we hand the OS the current mouse-down event via
// performWindowDragWithEvent: — the OS then runs its native drag loop
// (smooth, with edge snapping). Polling SetWindowPosition every frame is
// laggy and jittery on macOS, so we never do that.
// Only compiled on Darwin (file suffix), so no import guards needed here.

import "base:intrinsics"
import F "core:sys/darwin/Foundation"
import rl "vendor:raylib"

// Workaround for odin-lang/Odin#7793, a regression in the Odin compiler
// (dev-2026-10, commit bdb036473; shipped as Homebrew odin 2026-10). A plain
// Objective-C message send — like F.Application_sharedApplication() below —
// does not make the checker declare the runtime procedures the LLVM backend
// calls at startup, so compiling aborts with
// "missing procedure 'objc_lookUpClass'". Calling objc_find_class forces the
// checker to add them. Remove once Odin is newer than 2026-10-12 (fix landed
// in master via PR #7842).
@(init, private = "file")
_objc_missing_procs_workaround :: proc "contextless" () {
	_ = intrinsics.objc_find_class("NSObject")
}

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
