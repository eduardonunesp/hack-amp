package main

import "core:log"

engine_sub :: proc() {
	broker_register(.LoadMsg, "engine_load_sound", engine_on_load)
	broker_register(.PlayMsg, "engine_play_sound", engine_on_play)
	broker_register(.PauseMsg, "engine_pause_sound", engine_on_pause)
	broker_register(.StopMsg, "engine_stop_sound", engine_on_stop)
	broker_register(.SeekMsg, "engine_seek_sound", engine_on_seek)
}

engine_on_load :: proc(msg_data : MessageData) {
	data := msg_data.(LoadMsgData) or_else {}
	defer delete(data.path) // frees the path cloned by the poster

	_, err := sound_init(data.path)
	if err != .SUCCESS {
		log.errorf("ENGINE: failed to load file %s, %s", data.path, err)
	}

	if prev_sound, prev_ok := sound_by_handle(g_engine.curr_sound); prev_ok {
		if stop_err := sound_stop(prev_sound); stop_err != .SUCCESS {
			log.errorf("ENGINE: failed to stop sound: %s", prev_sound)
		}
	}
}

engine_on_play :: proc(msg_data : MessageData) {
	data := msg_data.(SoundMsgData) or_else {}
	if sound, ok := sound_by_handle(data.handle); ok {
		g_engine.curr_sound = data.handle
		if err := sound_start(sound); err != .SUCCESS {
			log.errorf("ENGINE: failed to play file %s, %s", sound.path, err)
		}
	}
}

engine_on_pause :: proc(msg_data : MessageData) {
	_ = msg_data.(SoundMsgData) or_else {}
	if sound, ok := sound_by_handle(g_engine.curr_sound); ok {
		if err := sound_stop(sound); err != .SUCCESS {
			log.errorf("ENGINE: failed to pause file %s, %s", sound.path, err)
		}
	}
}

engine_on_stop :: proc(msg_data : MessageData) {
	_ = msg_data.(SoundMsgData) or_else {}
	if sound, ok := sound_by_handle(g_engine.curr_sound); ok {
		if err := sound_stop(sound); err != .SUCCESS {
			log.errorf("ENGINE: failed to stop file %s, %s", sound.path, err)
		}
		if err := sound_seek_to_second(sound, 0); err != .SUCCESS {
			log.errorf("ENGINE: failed to reset file %s, %s", sound.path, err)
		}
	}
}

engine_on_seek :: proc(msg_data : MessageData) {
	data, ok := msg_data.(SeekMsgData)
	if !ok { return }
	if sound, sound_ok := sound_by_handle(data.handle); sound_ok {
		if err := sound_seek_to_second(sound, data.seconds); err != .SUCCESS {
			log.errorf(
				"ENGINE: failed to seek to pos file %s, %s",
				sound.path,
				err,
			)
		}
	}
}
