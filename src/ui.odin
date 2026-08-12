package main

import "./rlmu"
import "core:fmt"
import "core:log"
import "core:path/filepath"
import "core:strings"
import "core:time"
import mu "libs:microui"
import tf "libs:tinyfiledialogs"

DOUBLE_CLICK_THRESHOLD :: time.Millisecond * 300
UI_DIALOG_FILTER       :: [?]cstring{"*.mp3", "*.wav", "*.ogg", "*.flac"}
PLAYLIST_BUTTONS_BAR_H :: 36

seek_value : mu.Real = 0
seek_dragging : bool

ROW_SEL   :: mu.Color{255, 255, 255, 255}
ROW_TEXT  :: mu.Color{0, 255, 65, 255}
ROW_HOVER :: mu.Color{0, 80, 20, 255}

ui_theme :: proc(ctx : ^mu.Context) {
	ctx.style.colors = {
		.TEXT         = ROW_TEXT,
		.SELECTION_BG = {0, 100, 25, 255},
		.BORDER       = {0, 80, 20, 255},
		.WINDOW_BG    = {0, 0, 0, 255},
		.TITLE_BG     = {5, 20, 10, 255},
		.TITLE_TEXT   = {0, 230, 60, 255},
		.PANEL_BG     = {0, 0, 0, 0},
		.BUTTON       = {0, 60, 15, 255},
		.BUTTON_HOVER = {0, 90, 25, 255},
		.BUTTON_FOCUS = {0, 130, 35, 255},
		.BASE         = {0, 40, 10, 255},
		.BASE_HOVER   = {0, 70, 18, 255},
		.BASE_FOCUS   = {0, 100, 25, 255},
		.SCROLL_BASE  = {0, 30, 8, 255},
		.SCROLL_THUMB = {0, 120, 30, 255},
	}
}

// "Artist - Title" from tags, else the file name.
sound_ui_name :: proc(sound : ^Sound) -> string {
	if sound.artist != "" && sound.title != "" {
		return fmt.tprintf("%s - %s", sound.artist, sound.title)
	}
	if sound.title != "" {
		return sound.title
	}
	return filepath.base(sound.path)
}

ui_row :: proc(
	ctx : ^mu.Context,
	handle : Handle,
	name, duration : string,
	selected := false,
) -> bool {
	mu.layout_row(ctx, {-1}, 0)
	row := mu.layout_next(ctx)

	h := handle
	id := mu.get_id_rawptr(ctx, &h, size_of(h))
	mu.update_control(ctx, id, row, {})

	if ctx.hover_id == id {
		mu.draw_rect(ctx, row, ROW_HOVER)
	}

	inset := i32(6)
	left := row
	left.x += inset
	left.w = row.w / 2
	right := row
	right.x = row.x + row.w / 2
	right.w = row.w / 2
	color := ROW_SEL if selected else ROW_TEXT
	rlmu.set_list_label(name, left, .Left, color)
	rlmu.set_list_label(duration, right, .Right, color)

	return ctx.mouse_pressed_bits == {.LEFT} && ctx.focus_id == id
}

ui_shuffle_button :: proc(win := g_win) {
	base := win.ctx.style.colors[.BUTTON]
	if g_playlist.shuffle {
		win.ctx.style.colors[.BUTTON] = win.ctx.style.colors[.BUTTON_FOCUS]
	}
	if .SUBMIT in mu.button(win.ctx, "", .SHUFFLE) {
		g_playlist.shuffle = !g_playlist.shuffle
	}
	win.ctx.style.colors[.BUTTON] = base
}

ui_backward_button :: proc(win := g_win) {
	button_options : mu.Options = {.ALIGN_CENTER}
	if .SUBMIT in mu.button(win.ctx, "", .BACKWARD, button_options) {
		broker_post(.PlayPrevMsg, SoundMsgData{handle = g_engine.curr_sound})
	}
}

ui_play_pause_button :: proc(win := g_win) {
	if engine_is_playing() {
		if .SUBMIT in mu.button(win.ctx, "", .PAUSE) {
			broker_post(.PauseMsg, SoundMsgData{handle = g_engine.curr_sound})
		}
	} else {
		if .SUBMIT in mu.button(win.ctx, "", .PLAY) {
			if handle, ok := playlist_current(); ok {
				broker_post(.PlayMsg, SoundMsgData{handle = handle})
			}
		}
	}
}

ui_stop_button :: proc(win := g_win) {
	if .SUBMIT in mu.button(win.ctx, "", .STOP) {
		broker_post(.StopMsg, SoundMsgData{handle = g_engine.curr_sound})
	}
}

ui_forward_button :: proc(win := g_win) {
	button_options : mu.Options = {.ALIGN_CENTER}
	if .SUBMIT in mu.button(win.ctx, "", .FORWARD, button_options) {
		broker_post(
			.PlayForwardMsg,
			SoundMsgData{handle = g_engine.curr_sound},
		)
	}
}

ui_repeat_button :: proc(win := g_win) {
	base := win.ctx.style.colors[.BUTTON]
	if g_playlist.repeat {
		win.ctx.style.colors[.BUTTON] = win.ctx.style.colors[.BUTTON_FOCUS]
	}
	if .SUBMIT in mu.button(win.ctx, "", .REPEAT) {
		g_playlist.repeat = !g_playlist.repeat
	}
	win.ctx.style.colors[.BUTTON] = base
}

ui_load_button :: proc(win := g_win) {
	button_options : mu.Options = {.ALIGN_CENTER}
	if .SUBMIT in mu.button(win.ctx, "", .EJECT, button_options) {
		patterns := UI_DIALOG_FILTER
		cpath := tf.tinyfd_open_file_dialog(
			"Load Sound",
			"",
			len(patterns),
			&patterns[0],
			"Audio files",
			0,
		)
		if cpath == nil {
			log.debug("UI: file dialog cancelled")
			return
		}
		path := strings.clone(string(cpath))
		if err := broker_post(.LoadMsg, LoadMsgData{path = path});
		   err != .None {
			log.errorf("UI: failed to post LoadMsg for %s: %v", path, err)
			delete(path)
		}
	}
}

ui_seek_bar :: proc(win := g_win) {
	sound := sound_by_handle(g_engine.curr_sound) or_else &Sound{}
	info := sound_info(sound)

	slider_res := mu.slider(win.ctx, &seek_value, 0.0, 1.0, 0.001, "")

	if .CHANGE in slider_res {
		seek_dragging = true
	} else if seek_dragging {
		seek_dragging = false
		if _, ok := sound_by_handle(g_engine.curr_sound); ok {
			target := f64(seek_value) * info.total_seconds
			broker_post(
				.SeekMsg,
				SeekMsgData{handle = g_engine.curr_sound, seconds = target},
			)
		}
	}

	if !seek_dragging {
		seek_value =
			info.total_seconds > 0 ? mu.Real(info.curr_seconds / info.total_seconds) : 0
	}
}

ui_time_remain :: proc(win := g_win) {
	sound := sound_by_handle(g_engine.curr_sound) or_else &Sound{}
	sound_info := sound_info(sound)
	buf := strings.builder_make(context.temp_allocator)
	fmt.sbprintf(
		&buf,
		"%s / %s",
		format_mmss(sound_info.total_seconds),
		format_mmss(sound_info.curr_seconds),
	)
	rect := mu.layout_next(win.ctx)
	rlmu.set_timer_label(strings.to_string(buf), rect)
}

ui_main_playlist :: proc(win := g_win) {
	mu.layout_row(win.ctx, {-1}, 20)
	header_rect := mu.layout_next(win.ctx)
	mu.draw_rect(win.ctx, header_rect, {0, 40, 10, 255})
	rlmu.set_list_label("playlist", header_rect, .Center, ROW_SEL, false)

	mu.layout_row(win.ctx, {-1}, -1 - PLAYLIST_BUTTONS_BAR_H)
	mu.begin_panel(win.ctx, "Playlist", {.NO_CLOSE})
	rlmu.set_list_clip(mu.get_clip_rect(win.ctx))

	empty := true
	for handle, i in g_playlist.entries {
		empty = false
		sound := sound_by_handle(handle) or_continue
		info := sound_info(sound)
		display_name := sound_ui_name(sound)
		mouse_pressed := ui_row(
			win.ctx,
			handle,
			display_name,
			format_mmss(info.total_seconds),
			i == g_playlist.selected,
		)
		if mouse_pressed {
			now := time.tick_now()

			is_double_click :=
				g_playlist.last_click_tick._nsec != 0 &&
				handle == g_playlist.last_click_handle &&
				time.tick_diff(g_playlist.last_click_tick, now) <
					DOUBLE_CLICK_THRESHOLD

			g_playlist.selected = i

			if is_double_click {
				broker_post(
					.StopMsg,
					SoundMsgData{handle = g_engine.curr_sound},
				)
				broker_post(.PlayMsg, SoundMsgData{handle = handle})
				g_playlist.last_click_handle = {}
				g_playlist.last_click_tick = {}
			} else {
				g_playlist.last_click_handle = handle
				g_playlist.last_click_tick = now
			}
		}
	}
	if empty {
		mu.layout_row(win.ctx, {-1}, 0)
		rlmu.set_list_label(
			"(no tracks loaded)",
			mu.layout_next(win.ctx),
			.Left,
		)
	}

	mu.end_panel(win.ctx)
	ui_main_playlist_buttons()
}

ui_main_display :: proc(win := g_win) {
	mu.layout_row(win.ctx, {30, 100, 20, 210}, 50)
	mu.label(win.ctx, "")
	ui_time_remain()
	mu.label(win.ctx, "")
	mu.label(win.ctx, "")
}

ui_main_seek_bar :: proc(win := g_win) {
	mu.layout_row(win.ctx, {-1}, 10)
	ui_seek_bar()
}

ui_main_buttons :: proc(win := g_win) {
	mu.layout_row(win.ctx, {52, 54, 52, 52, 52, 52, 52}, 36)

	ui_backward_button()
	ui_play_pause_button()
	ui_stop_button()
	ui_forward_button()
	ui_load_button()
	ui_shuffle_button()
	ui_repeat_button()
}

ui_main_playlist_clear_button :: proc(win := g_win) {
	button_options : mu.Options = {.ALIGN_CENTER}
	if .SUBMIT in mu.button(win.ctx, "clear", .NONE, button_options) {
		broker_post(.PlaylistClear)
	}
}

ui_main_playlist_load_dir_button :: proc(win := g_win) {
	button_options : mu.Options = {.ALIGN_CENTER}
	if .SUBMIT in mu.button(win.ctx, "load", .NONE, button_options) {
		folder := tf.tinyfd_select_folder_dialog("Load Folder", "")
		if folder == nil {
			log.debug("UI: folder dialog cancelled")
			return
		}
		path := strings.clone(string(folder))
		defer delete(path)
		playlist_scan_folder(path)
	}
}

ui_main_playlist_buttons :: proc(win := g_win) {
	layout := mu.get_layout(win.ctx)
	bar_h := layout.body.h - layout.next_row
	if bar_h <= 0 { return }
	mu.layout_row(win.ctx, {50, -1, 50}, bar_h)

	ui_main_playlist_clear_button()
	ui_main_playlist_load_dir_button()
}

ui_main :: proc(win := g_win) {
	ui_theme(win.ctx)

	window_options : mu.Options = {
		.NO_INTERACT,
		.NO_CLOSE,
		.ALIGN_CENTER,
		.NO_FRAME,
	}
	if mu.begin_window(
		win.ctx,
		win.title,
		mu.Rect{0, 0, win.width, win.height},
		window_options,
	) {
		defer mu.end_window(g_win.ctx)

		ui_main_display()
		ui_main_seek_bar()
		ui_main_buttons()
		ui_main_playlist()
	}
}
