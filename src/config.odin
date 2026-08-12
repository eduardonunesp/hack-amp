package main

import "core:encoding/ini"
import "core:fmt"
import "core:log"
import "core:os"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

CONFIG_DIR  :: ".hack-amp"
CONFIG_FILE :: "config.ini"
CONFIG_BASE :: `
[config]
lpx = 0
lpy = 0

[playlist]
size = 0
`

Config :: struct {
	lpx, lpy : int,
	home_ok  : bool,
	home     : string,
}

g_config : Config

config_init :: proc() {
	home := os.user_home_dir(context.temp_allocator) or_else ""
	if home == "" {
		log.errorf("homedir not found can't save user configurations")
	}
	g_config = {
		home_ok = home != "",
		home    = strings.clone(home),
	}
	config_load_user_config()
	config_apply_last_pos()
}

config_uninit :: proc() {
	config_save_user_config()
	delete(g_config.home)
}

config_get_user_config :: proc() -> string {
	if !g_config.home_ok {
		return ""
	}

	hackamp_home_path := fmt.tprintf("%s/%s", g_config.home, CONFIG_DIR)
	if !os.is_dir(hackamp_home_path) {
		os.make_directory(hackamp_home_path)
	}

	hackamp_config_path := fmt.tprintf("%s/%s", hackamp_home_path, CONFIG_FILE)
	if !os.exists(hackamp_config_path) {
		config_create_user_config(hackamp_config_path)
	}

	return hackamp_config_path
}

config_create_user_config :: proc(hackamp_config_path : string) {
	config_map, err_load_map := ini.load_map_from_string(
		CONFIG_BASE,
		context.temp_allocator,
	)
	if err_load_map != .None {
		log.errorf("failed to load initial configuration")
		return
	}

	f, err_open_file := os.open(hackamp_config_path, {.Read, .Write, .Create})
	if err_open_file != os.ERROR_NONE {
		log.errorf("failed to open initial configuration")
		return
	}
	defer os.close(f)

	_, err_write_map := ini.write_map(os.to_stream(f), config_map)
	if err_write_map != .None {
		log.errorf("failed to write initial configuratin")
	}
}

config_load_user_config :: proc() {
	config := config_get_user_config()
	if config == "" {
		return
	}

	config_map, err_load_map, _ := ini.load_map_from_path(
		config,
		context.temp_allocator,
	)
	if err_load_map != .None {
		log.errorf("failed to load user config: %s", err_load_map)
		return
	}

	if section, ok := config_map["config"]; ok {
		if lpx_s, lpx_ok := section["lpx"]; lpx_ok {
			if lpx, lpx_parsed := strconv.parse_int(lpx_s); lpx_parsed {
				g_config.lpx = lpx
			}
		}
		if lpy_s, lpy_ok := section["lpy"]; lpy_ok {
			if lpy, lpy_parsed := strconv.parse_int(lpy_s); lpy_parsed {
				g_config.lpy = lpy
			}
		}
	}

	if section, ok := config_map["playlist"]; ok {
		plist_size : int
		if plist_size_s, size_ok := section["size"]; size_ok {
			if size, size_parsed := strconv.parse_int(plist_size_s);
			   size_parsed {
				plist_size = size
			}
		}

		for i in 0 ..< plist_size {
			sound_idx := fmt.tprintf("sound_%d", i)
			if file_path, path_ok := section[sound_idx]; path_ok {
				broker_post(
					.LoadMsg,
					LoadMsgData{path = strings.clone(file_path)},
				)
			}
		}
	}
}

config_save_user_config :: proc() {
	config := config_get_user_config()
	if config == "" {
		return
	}
	config_save_last_pos()

	f, err_open_file := os.open(config, {.Trunc, .Write})
	if err_open_file != os.ERROR_NONE {
		log.errorf("failed to open user configuration")
		return
	}
	defer os.close(f)

	config_map, err := ini.load_map_from_string(
		CONFIG_BASE,
		context.temp_allocator,
	)
	if err != .None {
		log.error("failed to load ini from string before save")
		return
	}
	config_pairs := &config_map["config"]
	config_pairs["lpx"] = fmt.tprint(g_config.lpx)
	config_pairs["lpy"] = fmt.tprint(g_config.lpy)

	playlist_pairs := &config_map["playlist"]
	for handle, i in g_playlist.entries {
		sound := sound_by_handle(handle) or_continue
		playlist_pairs[fmt.tprintf("sound_%d", i)] = sound.path
	}
	playlist_pairs["size"] = fmt.tprint(len(g_playlist.entries))

	_, err_write_map := ini.write_map(os.to_stream(f), config_map)
	if err_write_map != .None {
		log.errorf("failed to write user configuratin")
	}
}

config_save_last_pos :: proc() {
	win_pos := rl.GetWindowPosition()
	g_config.lpx, g_config.lpy = int(win_pos.x), int(win_pos.y)
}

config_apply_last_pos :: proc() {
	if g_config.lpx != 0 || g_config.lpy != 0 {
		rl.SetWindowPosition(i32(g_config.lpx), i32(g_config.lpy))
	}
}
