package main

import "core:log"
import "core:path/filepath"
import "core:strings"

AUDIO_EXTENSIONS :: []string{".mp3", ".wav", ".ogg", ".flac"}

is_audio_file :: proc(path : string) -> bool {
	ext := filepath.ext(path)
	for candidate in AUDIO_EXTENSIONS {
		if strings.equal_fold(ext, candidate) {
			return true
		}
	}
	return false
}

// Posts one LoadMsg per audio file found in `folder`. Each path is an owned
// clone; the engine handler frees it after sound_init copies it.
playlist_scan_folder :: proc(folder : string) -> (loaded : int) {
	w := filepath.walker_create(folder)
	defer filepath.walker_destroy(&w)

	for info in filepath.walker_walk(&w) {
		_ = filepath.walker_error(&w) or_break

		if info.type != .Regular || !is_audio_file(info.fullpath) {
			continue
		}

		path := strings.clone(info.fullpath)
		if err := broker_post(.LoadMsg, LoadMsgData{path = path});
		   err != .None {
			log.errorf("SCAN: failed to post LoadMsg for %s: %v", path, err)
			delete(path)
			continue
		}
		loaded += 1
	}

	if path, err := filepath.walker_error(&w); err != nil {
		log.errorf("SCAN: failed walking %s: %v", path, err)
	}
	log.infof("SCAN: posted %d audio files from %s", loaded, folder)
	return
}
