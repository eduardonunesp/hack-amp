package main

import rt "base:runtime"
import hm "core:container/handle_map"
import "core:fmt"
import "core:log"
import "core:strings"
import ma "vendor:miniaudio"

SoundErr :: union {
	ma.result,
	rt.Allocator_Error,
	PlaylistErr,
}

SoundInfo :: struct {
	playing       : bool,
	total_seconds : f64,
	curr_seconds  : f64,
}

Sound :: struct {
	handle       : Handle,
	inner        : ^ma.sound,
	info         : SoundInfo,
	path         : string,
	title        : string,
	artist       : string,
	album        : string,
	year         : string,
	tag_duration : f64,
}

sound_init :: proc(path : string) -> (Handle, SoundErr) {
	sound := new(Sound)
	defer free(sound)
	sound.inner = new(ma.sound)
	sound.path = strings.clone(path)

	if result := ma.sound_init_from_file(
		&g_engine.inner,
		fmt.ctprint(path),
		{.STREAM},
		nil,
		nil,
		sound.inner,
	); result != .SUCCESS {
		free(sound.inner)
		delete(sound.path)
		return {}, result
	}

	if tags, ok := tag_read(path); ok {
		sound.title = tags.title
		sound.artist = tags.artist
		sound.album = tags.album
		sound.year = tags.year
		sound.tag_duration = tags.total_seconds
	}

	handle, err := engine_add(sound^)
	if err != .None {
		free(sound.inner)
		delete(sound.path)
		delete(sound.title)
		delete(sound.artist)
		delete(sound.album)
		delete(sound.year)
		return {}, err
	}

	playlist_add(handle)
	return handle, .SUCCESS
}

sound_uninit :: proc(sound : ^Sound) {
	ma.sound_uninit(sound.inner)
	free(sound.inner)
	delete(sound.path)
	delete(sound.title)
	delete(sound.artist)
	delete(sound.album)
	delete(sound.year)
}

sound_by_handle :: proc(handle : Handle) -> (sound : ^Sound, ok : bool) {
	sound = hm.get(&g_engine.sounds, handle) or_return
	return sound, true
}

sound_start :: proc(sound : ^Sound) -> SoundErr {
	return ma.sound_start(sound.inner)
}

sound_stop :: proc(sound : ^Sound) -> SoundErr {
	return ma.sound_stop(sound.inner)
}

sound_seek_to_second :: proc(sound : ^Sound, seconds : f64) -> SoundErr {
	total : f32 = 0
	if result := ma.sound_get_length_in_seconds(sound.inner, &total);
	   result != .SUCCESS {
		return result
	}
	clamped := clamp(f32(seconds), 0, total)
	result := ma.sound_seek_to_second(sound.inner, clamped)
	if result != .SUCCESS {
		log.errorf(
			"SOUND: seek to %.2fs failed for %s: %s",
			clamped,
			sound.path,
			result,
		)
	}
	return result
}

sound_info :: proc(sound : ^Sound) -> SoundInfo {
	playing := ma.sound_is_playing(sound.inner)
	total_seconds : f32 = 0
	if result := ma.sound_get_length_in_seconds(sound.inner, &total_seconds);
	   result != .SUCCESS {
		return {}
	}
	return {
		playing = playing == true,
		total_seconds = f64(total_seconds),
		curr_seconds = f64(ma.sound_get_time_in_milliseconds(sound.inner)) /
		1000,
	}
}
