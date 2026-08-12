package main

import rt "base:runtime"
import "core:math/rand"
import "core:time"
import ma "vendor:miniaudio"

PlaylistErr :: union {
	rt.Allocator_Error,
}

Playlist :: struct {
	entries           : [dynamic]Handle,
	selected          : int, // index into entries; -1 when empty
	shuffle           : bool,
	repeat            : bool,
	last_click_handle : Handle,
	last_click_tick   : time.Tick,
}

g_playlist : Playlist

playlist_init :: proc() {
	g_playlist.selected = -1
	broker_register(.PlayForwardMsg, "on_play_next", playlist_next)
	broker_register(.PlayPrevMsg, "on_play_prev", playlist_prev)
	broker_register(.PlaylistClear, "on_playlist_clear", playlist_clear)
}

playlist_add :: proc(handle : Handle) {
	append(&g_playlist.entries, handle)
	if g_playlist.selected < 0 {
		g_playlist.selected = 0
	}
}

playlist_current :: proc() -> (Handle, bool) {
	return playlist_at_pos(g_playlist.selected)
}

playlist_at_pos :: proc(pos : int) -> (Handle, bool) {
	if pos < 0 || pos >= len(g_playlist.entries) {
		return {}, false
	}
	return g_playlist.entries[pos], true
}

playlist_next :: proc(msgData : MessageData) {
	n := len(g_playlist.entries)
	if n == 0 { return }
	prev := g_playlist.selected
	g_playlist.selected =
		g_playlist.shuffle ? playlist_random_other(n, prev) : (prev + 1) % n
	playlist_switch(prev)
}

playlist_prev :: proc(msgData : MessageData) {
	n := len(g_playlist.entries)
	if n == 0 { return }
	prev := g_playlist.selected
	g_playlist.selected = (prev - 1 + n) % n
	playlist_switch(prev)
}

playlist_switch :: proc(prev : int) {
	if prev_handle, ok := playlist_at_pos(prev); ok {
		broker_post(.StopMsg, SoundMsgData{handle = prev_handle})
	}
	if handle, ok := playlist_current(); ok {
		broker_post(.PlayMsg, SoundMsgData{handle = handle})
	}
}

// Random index in [0, n) that is not `exclude`.
playlist_random_other :: proc(n, exclude : int) -> int {
	if n <= 1 { return 0 }
	idx := rand.int_max(n - 1)
	if idx >= exclude { idx += 1 }
	return idx
}

playlist_tick :: proc() {
	if !g_playlist.repeat { return }
	sound, ok := sound_by_handle(g_engine.curr_sound)
	if !ok { return }
	if ma.sound_at_end(sound.inner) {
		broker_post(
			.SeekMsg,
			SeekMsgData{handle = g_engine.curr_sound, seconds = 0},
		)
		broker_post(.PlayMsg, SoundMsgData{handle = g_engine.curr_sound})
	}
}

playlist_clear :: proc(_ : MessageData) {
	clear(&g_playlist.entries)
	g_playlist.selected = -1
	g_playlist.last_click_handle = {}
	g_playlist.last_click_tick = {}
}

playlist_uninit :: proc() {
	delete(g_playlist.entries)
}
