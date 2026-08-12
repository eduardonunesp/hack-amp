# External static libs the Odin `foreign import` directives link against.
STATIC_LIBS := libs/tinyfiledialogs/libtinyfiledialogs.a libs/taglib_bindings/libtag_c.a

.PHONY: check
check: $(STATIC_LIBS)
	odin check ./src -collection:libs=libs -strict-style -vet -vet-semicolon -vet-using-param -warnings-as-errors

.PHONY: run
run: $(STATIC_LIBS)
	odin run ./src -collection:libs=libs -debug -out:bin/hack-amp

.PHONY: build
build: $(STATIC_LIBS)
	odin build ./src -collection:libs=libs -debug -out:bin/hack-amp

.PHONY: release
release: $(STATIC_LIBS)
	odin build ./src -collection:libs=libs -o:speed -lto:thin -disable-assert -source-code-locations:none -out:bin/hack-amp

# tinyfiledialogs is a single-file C library. Odin cannot compile/link .c
# files directly, so we precompile it into a static archive that the
# `foreign import` in libs/tinyfiledialogs/tinyfd.odin links against.
libs/tinyfiledialogs/libtinyfiledialogs.a: libs/tinyfiledialogs/tinyfiledialogs.c
	clang -O2 -c $< -o libs/tinyfiledialogs/tinyfiledialogs.o
	ar rcs $@ libs/tinyfiledialogs/tinyfiledialogs.o

# TagLib is a C++ library. Odin cannot compile/link C++ directly, so we use
# TagLib's own CMake to build the C wrapper (`tag_c`) as a static archive.
# Only MPEG/ID3 support is enabled — everything else is trimmed to keep the
# archive small and avoid extra dependencies. The `foreign import` in
# libs/taglib_bindings/taglib.odin links against libtag_c.a (which must sit
# next to the bindings file; Odin resolves the path relative to it).
#
# TagLib is a git submodule (pinned to v2.3.1) at libs/taglib;
# `git submodule update --init --recursive` fetches it on a fresh clone.
TAGLIB_SRC_DIR := libs/taglib
TAGLIB_BINDINGS_DIR := libs/taglib_bindings
TAGLIB_CMAKE_DIR := bin/taglib-build
TAGLIB_CMAKE_FLAGS := \
	-DBUILD_SHARED_LIBS=OFF \
	-DBUILD_BINDINGS=ON \
	-DBUILD_EXAMPLES=OFF \
	-DBUILD_TESTING=OFF \
	-DBUILD_FRAMEWORK=OFF \
	-DVISIBILITY_HIDDEN=OFF \
	-DWITH_ZLIB=OFF \
	-DWITH_MP4=OFF \
	-DWITH_ASF=OFF \
	-DWITH_DSF=OFF \
	-DWITH_MATROSKA=OFF \
	-DWITH_MOD=OFF \
	-DWITH_SHORTEN=OFF \
	-DWITH_TRUEAUDIO=OFF \
	-DWITH_RIFF=OFF \
	-DWITH_VORBIS=OFF \
	-DWITH_APE=OFF \
	-DCMAKE_BUILD_TYPE=Release

# Fetch the TagLib submodule (and its own utfcpp submodule) on demand.
$(TAGLIB_SRC_DIR)/CMakeLists.txt:
	git submodule update --init --recursive

$(TAGLIB_BINDINGS_DIR)/libtag_c.a: $(TAGLIB_SRC_DIR)/CMakeLists.txt
	mkdir -p $(TAGLIB_CMAKE_DIR)
	cmake -S $(TAGLIB_SRC_DIR) -B $(TAGLIB_CMAKE_DIR) $(TAGLIB_CMAKE_FLAGS)
	cmake --build $(TAGLIB_CMAKE_DIR) --target tag_c -j
	# tag_c links PRIVATELY against the core `tag` archive, so libtag_c.a
	# only holds tag_c.cpp.o and has unresolved symbols. Merge the two
	# archives into a single static library so the Odin `foreign import
	# lib "libtag_c.a"` resolves everything at once.
	libtool -static -o $@ $(TAGLIB_CMAKE_DIR)/bindings/c/libtag_c.a $(TAGLIB_CMAKE_DIR)/taglib/libtag.a

.PHONY: clean
clean:
	rm -rf *.o *.exe hack-amp src.bin src.bin.dSYM 
	rm -rf libs/tinyfiledialogs/tinyfiledialogs.o
	rm -rf libs/tinyfiledialogs/libtinyfiledialogs.a
	rm -rf libs/taglib_bindings/libtag_c.a
	rm -rf $(TAGLIB_CMAKE_DIR)
	mkdir -p bin
	touch bin/.gitkeep