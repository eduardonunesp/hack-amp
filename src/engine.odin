package main

import hm "core:container/handle_map"
import ma "vendor:miniaudio"

Handle    :: hm.Handle32
HandleMap :: hm.Dynamic_Handle_Map

EngineErr :: union {
	ma.result,
}

Engine :: struct {
	curr_sound : Handle,
	inner      : ma.engine,
	sounds     : HandleMap(Sound, Handle),
}

g_engine : Engine

engine_init :: proc() -> EngineErr {
	hm.dynamic_init(&g_engine.sounds, context.allocator)
	return ma.engine_init(nil, &g_engine.inner)
}

engine_is_playing :: proc() -> bool {
	sound := sound_by_handle(g_engine.curr_sound) or_return
	return sound_info(sound).playing
}

engine_add :: proc(sound : Sound) -> (Handle, PlaylistErr) {
	handle, err := hm.add(&g_engine.sounds, sound)
	if err != .None {
		return {}, err
	}
	return handle, .None
}

engine_uninit :: proc() {
	it := hm.iterator_make(&g_engine.sounds)
	for sound, _ in hm.iterate(&it) {
		sound_uninit(sound)
	}
	hm.dynamic_destroy(&g_engine.sounds)
	ma.engine_uninit(&g_engine.inner)
}
