package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"

// fmt/mem are only used in the debug leak report below.
_ :: fmt
_ :: mem

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger()
		track : mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf(
					"=== %v allocations not freed ===\n",
					len(track.allocation_map),
				)
				for _, entry in track.allocation_map {
					fmt.eprintf(
						"- %v bytes @ %v\n",
						entry.size,
						entry.location,
					)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf(
					"=== %v incorrect frees ===\n",
					len(track.bad_free_array),
				)
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	broker_init()
	defer broker_destroy()

	if result := engine_init(); result != .SUCCESS {
		log.error("failed to init sound for file")
		os.exit(-1)
	}
	defer engine_uninit()

	playlist_init()
	defer playlist_uninit()

	engine_sub()

	win_init(WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT)
	defer win_uninit()

	config_init()
	defer config_uninit()

	for !win_should_close() {
		defer free_all(context.temp_allocator)
		broker_process_messages()
		playlist_tick()
		win_main()
	}
}
