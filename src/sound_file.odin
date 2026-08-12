package main

import "core:fmt"
import "core:strings"
import tl "libs:taglib_bindings"
import ma "vendor:miniaudio"

SoundFileInfo :: struct {
	sample_rate   : u32,
	channels      : u32,
	format        : ma.format,
	total_seconds : f64,
	bit_depth     : int,
	title         : string,
	artist        : string,
	album         : string,
	year          : string,
}

// Reads ID3 tags + audio properties via TagLib. Missing fields are left empty.
tag_read :: proc(path : string) -> (info : SoundFileInfo, ok : bool) {
	file := tl.taglib_file_new(fmt.ctprint(path))
	if file == nil do return {}, false
	defer tl.taglib_file_free(file)
	if !tl.taglib_file_is_valid(file) do return {}, false
	defer tl.taglib_tag_free_strings()

	if tag := tl.taglib_file_tag(file); tag != nil {
		if s := tl.taglib_tag_title(tag); s != nil do info.title = strings.clone(string(s))
		if s := tl.taglib_tag_artist(tag); s != nil do info.artist = strings.clone(string(s))
		if s := tl.taglib_tag_album(tag); s != nil do info.album = strings.clone(string(s))
		if y := tl.taglib_tag_year(tag); y != 0 do info.year = fmt.tprintf("%d", y)
	}

	if ap := tl.taglib_file_audioproperties(file); ap != nil {
		if l := tl.taglib_audioproperties_length(ap); l > 0 do info.total_seconds = f64(l)
		if r := tl.taglib_audioproperties_samplerate(ap); r > 0 do info.sample_rate = u32(r)
		if c := tl.taglib_audioproperties_channels(ap); c > 0 do info.channels = u32(c)
	}

	return info, true
}
