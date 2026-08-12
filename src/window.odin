package main

import "./rlmu"
import "core:fmt"
import mu "libs:microui"
import rl "vendor:raylib"

WINDOW_FPS :: 60
WINDOW_CLS :: rl.BLACK

Window :: struct {
	title         : string,
	width, height : i32,
	ctx           : ^mu.Context,
}

g_win : Window

win_init :: proc(title : string, width, height : i32) {
	when ODIN_DEBUG {
		rl.SetTraceLogLevel(rl.TraceLogLevel.ALL)
	} else {
		rl.SetTraceLogLevel(rl.TraceLogLevel.ERROR)
	}

	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_UNDECORATED})
	rl.InitWindow(width, height, fmt.ctprint(title))
	rl.SetTargetFPS(WINDOW_FPS)
	rl.SetWindowMinSize(WINDOW_MIN_WIDTH, WINDOW_MIN_HEIGHT)

	when !ODIN_DEBUG {
		rl.SetExitKey(rl.KeyboardKey.KEY_NULL)
	}

	g_win.title = title
	g_win.width = width
	g_win.height = height
	g_win.ctx = rlmu.init_scope()
}

win_uninit :: proc() {
	rlmu.destroy()
	rl.CloseWindow()
	free_all(context.temp_allocator)
}

win_main :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.Color(WINDOW_CLS))

	rlmu.begin_scope()
	ui_main()
}

win_should_close :: proc() -> bool {
	return rl.WindowShouldClose()
}
