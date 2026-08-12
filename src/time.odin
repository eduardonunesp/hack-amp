package main

import "core:fmt"

format_mmss :: proc(total_seconds : f64 = 0) -> string {
	if total_seconds <= 0 {
		return fmt.tprintf("--:--")
	}
	mins : int = int(total_seconds) / 60
	secs : int = int(total_seconds) % 60
	return fmt.tprintf("%02d:%02d", mins, secs)
}
