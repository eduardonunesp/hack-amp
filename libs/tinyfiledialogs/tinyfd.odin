// Odin bindings for tinyfiledialogs: a cross-platform file dialog library
// (https://tinyfiledialogs.sourceforge.net). On macOS it shells out to
// osascript/System Events, on Linux to zenity/kdialog, on Windows it uses the
// Win32 common dialogs.
//
// The C implementation is compiled into a static archive and linked through
// the foreign import below. The archive is built by the repo Makefile
// (rule `libs/tinyfiledialogs/libtinyfiledialogs.a`) from
// `tinyfiledialogs.c`, because Odin cannot compile/link .c files directly.
//
// NOTE: every function that returns a cstring returns a pointer into a
// statically preallocated buffer inside the C library. The content is only
// valid until the next dialog call, so callers must copy the string out
// immediately (e.g. `strings.clone`).
package tinyfd

foreign import lib "libtinyfiledialogs.a"

@(default_calling_convention = "c")
foreign lib {
	// Current version number, e.g. "v3.21.3".
	tinyfd_version: [8]u8

	// Info about requirements, e.g. on unix the packages needed.
	tinyfd_needs: [^]u8

	// 0 (default) or 1: on unix, prints the command line calls.
	tinyfd_verbose: i32

	// 1 (default) or 0: on unix, hides errors and warnings from dialogs.
	tinyfd_silent: i32

	// 0 (default) or 1: enables the (unix only) curses console dialogs.
	tinyfd_allow_curses_dialogs: i32

	// 0 (default) or 1: forces all dialogs into console mode.
	tinyfd_force_console: i32

	// Filled with the backend solution ("zenity", "applescript", ...) after
	// a `tinyfd_query` call.
	tinyfd_response: [1024]u8

	@(link_name = "tinyfd_beep")
	tinyfd_beep :: proc() ---

	// "info", "warning" or "error".
	@(link_name = "tinyfd_notifyPopup")
	tinyfd_notify_popup :: proc(
		a_title: cstring,
		a_message: cstring,
		a_icon_type: cstring,
	) -> i32 ---

	// a_dialog_type: "ok", "okcancel", "yesno", "yesnocancel".
	// a_icon_type: "info", "warning", "error", "question".
	// Returns 0 for cancel/no, 1 for ok/yes, 2 for no in yesnocancel.
	@(link_name = "tinyfd_messageBox")
	tinyfd_message_box :: proc(
		a_title: cstring,
		a_message: cstring,
		a_dialog_type: cstring,
		a_icon_type: cstring,
		a_default_button: i32,
	) -> i32 ---

	// Returns NULL on cancel. a_default_input nil = password box,
	// "" = plain input box.
	@(link_name = "tinyfd_inputBox")
	tinyfd_input_box :: proc(
		a_title: cstring,
		a_message: cstring,
		a_default_input: cstring,
	) -> cstring ---

	// Returns NULL on cancel. a_default_path_and_or_file nil or ""; ends
	// with / to set only a directory.
	@(link_name = "tinyfd_saveFileDialog")
	tinyfd_save_file_dialog :: proc(
		a_title: cstring,
		a_default_path_and_or_file: cstring,
		a_num_of_filter_patterns: i32,
		a_filter_patterns: [^]cstring,
		a_single_filter_description: cstring,
	) -> cstring ---

	// Returns NULL on cancel. With multiple selects (1) the result is a
	// list of paths separated by '|'. a_filter_patterns is e.g.
	// [^]cstring{"*.mp3", "*.wav"} with the matching count.
	@(link_name = "tinyfd_openFileDialog")
	tinyfd_open_file_dialog :: proc(
		a_title: cstring,
		a_default_path_and_or_file: cstring,
		a_num_of_filter_patterns: i32,
		a_filter_patterns: [^]cstring,
		a_single_filter_description: cstring,
		a_allow_multiple_selects: i32,
	) -> cstring ---

	// Returns NULL on cancel.
	@(link_name = "tinyfd_selectFolderDialog")
	tinyfd_select_folder_dialog :: proc(
		a_title: cstring,
		a_default_path: cstring,
	) -> cstring ---

	// Returns the hex color "#FF0000" or NULL on cancel. a_default_rgb and
	// a_result_rgb may be the same buffer.
	@(link_name = "tinyfd_colorChooser")
	tinyfd_color_chooser :: proc(
		a_title: cstring,
		a_default_hex_rgb: cstring,
		a_default_rgb: [^]u8,
		a_result_rgb: [^]u8,
	) -> cstring ---
}

// Windows only UTF-16 variants of the dialogs above. Not available on other
// platforms; the C code guards them with _WIN32.
when ODIN_OS == .Windows {
	@(default_calling_convention = "c")
	foreign lib {
		@(link_name = "tinyfd_notifyPopupW")
		tinyfd_notify_popup_w :: proc(
			a_title: cstring,
			a_message: cstring,
			a_icon_type: cstring,
		) -> i32 ---

		@(link_name = "tinyfd_messageBoxW")
		tinyfd_message_box_w :: proc(
			a_title: cstring,
			a_message: cstring,
			a_dialog_type: cstring,
			a_icon_type: cstring,
			a_default_button: i32,
		) -> i32 ---

		@(link_name = "tinyfd_inputBoxW")
		tinyfd_input_box_w :: proc(
			a_title: cstring,
			a_message: cstring,
			a_default_input: cstring,
		) -> cstring ---

		@(link_name = "tinyfd_saveFileDialogW")
		tinyfd_save_file_dialog_w :: proc(
			a_title: cstring,
			a_default_path_and_or_file: cstring,
			a_num_of_filter_patterns: i32,
			a_filter_patterns: [^]cstring,
			a_single_filter_description: cstring,
		) -> cstring ---

		@(link_name = "tinyfd_openFileDialogW")
		tinyfd_open_file_dialog_w :: proc(
			a_title: cstring,
			a_default_path_and_or_file: cstring,
			a_num_of_filter_patterns: i32,
			a_filter_patterns: [^]cstring,
			a_single_filter_description: cstring,
			a_allow_multiple_selects: i32,
		) -> cstring ---

		@(link_name = "tinyfd_selectFolderDialogW")
		tinyfd_select_folder_dialog_w :: proc(
			a_title: cstring,
			a_default_path: cstring,
		) -> cstring ---

		@(link_name = "tinyfd_colorChooserW")
		tinyfd_color_chooser_w :: proc(
			a_title: cstring,
			a_default_hex_rgb: cstring,
			a_default_rgb: [^]u8,
			a_result_rgb: [^]u8,
		) -> cstring ---
	}
}
