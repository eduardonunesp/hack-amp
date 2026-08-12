package main

// Header-only window dragging for Windows. On a left press inside the header
// strip we send WM_NCLBUTTONDOWN with HTCAPTION: Windows then runs its native
// caption drag loop (smooth, with Aero snap and maximize-on-top-edge).
// Only compiled on Windows (file suffix), so no import guards needed here.

import "core:sys/windows"
import rl "vendor:raylib"

win_drag :: proc() {
	if !rl.IsMouseButtonPressed(.LEFT) {
		return
	}
	if rl.GetMousePosition().y > HEADER_DRAG_H {
		return
	}

	hwnd := windows.HWND(rl.GetWindowHandle())
	windows.ReleaseCapture()
	windows.SendMessageW(
		hwnd,
		windows.WM_NCLBUTTONDOWN,
		windows.WPARAM(windows.HTCAPTION),
		0,
	)
}
