// Odin bindings for TagLib's C API (bindings/c/tag_c.h). TagLib is C++ and
// cannot be linked by Odin directly, so we use its C wrapper, precompiled to
// a static archive by the Makefile (same pattern as libs/tinyfiledialogs).
//
// Strings returned by getters are cached by TagLib and freed in one shot by
// taglib_tag_free_strings(); a missing field returns NULL, not "".
package taglib

// TagLib is C++, so also link the C++ standard library (clang, not clang++,
// won't pull it in automatically).
foreign import lib {
	"libtag_c.a",
	"system:c++",
}

TagLib_File :: struct{}
TagLib_Tag  :: struct{}
TagLib_AudioProperties :: struct{}

@(default_calling_convention = "c")
foreign lib {
	taglib_file_new    :: proc(filename: cstring) -> ^TagLib_File --- // NULL if type unknown/unreadable
	taglib_file_is_valid :: proc(file: ^TagLib_File) -> b32 ---
	// Tag/audio properties below are BORROWED: freed with the file, never alone.
	taglib_file_tag    :: proc(file: ^TagLib_File) -> ^TagLib_Tag ---
	taglib_file_audioproperties :: proc(file: ^TagLib_File) -> ^TagLib_AudioProperties ---
	taglib_file_free   :: proc(file: ^TagLib_File) ---

	// UTF-8 fields; NULL when unset.
	taglib_tag_title  :: proc(tag: ^TagLib_Tag) -> cstring ---
	taglib_tag_artist :: proc(tag: ^TagLib_Tag) -> cstring ---
	taglib_tag_album  :: proc(tag: ^TagLib_Tag) -> cstring ---
	taglib_tag_year   :: proc(tag: ^TagLib_Tag) -> u32 --- // 0 when unset
	// Frees ALL cached tag strings. Call after copying what you need.
	taglib_tag_free_strings :: proc() ---

	taglib_audioproperties_length     :: proc(ap: ^TagLib_AudioProperties) -> i32 --- // seconds
	taglib_audioproperties_samplerate :: proc(ap: ^TagLib_AudioProperties) -> i32 --- // Hz
	taglib_audioproperties_channels   :: proc(ap: ^TagLib_AudioProperties) -> i32 ---
}
