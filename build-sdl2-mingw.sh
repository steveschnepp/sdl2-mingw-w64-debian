#! /bin/sh
# Create sdl2-mingw-w64-x86-64-dev & sdl2-mingw-w64-i686-dev debian packages
# Typical usage
# ./build-sdl2-mingw.sh "" 2.30.2           # core SDL2
# ./build-sdl2-mingw.sh image 2.8.2         # SDL_image
# ./build-sdl2-mingw.sh mixer 2.8.0         # SDL_mixer
# ./build-sdl2-mingw.sh ttf 2.22.0          # SDL_ttf
# ./build-sdl2-mingw.sh net 2.2.0           # SDL_net

set -e

PKG="$1"
VER="$2"

[ -z "$PKG" ] && PKG="core"
[ -z "$VER" ] && { echo "Missing VER parameter"; exit 1; }

ARCHS="x86_64 i686"
TMPDIR="$(mktemp -d)"

# Construct download URL
if [ "$PKG" = "core" ]; then
	ZIPNAME="SDL2-devel-${VER}-mingw.tar.gz"
	BASE_URL="https://github.com/libsdl-org/SDL/releases/download/release-${VER}/${ZIPNAME}"
	DEB_PKG="sdl2"
	LIBNAME="SDL2"
else
	PKG_UPPER=$(echo "$PKG" | tr 'a-z' 'A-Z')
	ZIPNAME="SDL2_${PKG}-devel-${VER}-mingw.tar.gz"
	BASE_URL="https://github.com/libsdl-org/SDL_${PKG}/releases/download/release-${VER}/${ZIPNAME}"
	DEB_PKG="sdl2${PKG}"
	LIBNAME="SDL2_${PKG}"
fi

wget --continue -O "$ZIPNAME" "$BASE_URL"
tar -f "$ZIPNAME" -C "$TMPDIR" -zxv

(
	cd "$TMPDIR"

	for ARCH in $ARCHS; do
		DEB_ARCH=$(echo $ARCH | tr "_" "-")
		TARGET="${ARCH}-w64-mingw32"
		DST="${TMPDIR}/install-${ARCH}-${PKG}"
		mkdir -p "$DST/usr/$TARGET"

		SRC_DIR="$(find . -type d -name "${ARCH}*w64*")"
		SRC_DIR="$(find "${LIBNAME}-${VER}" -type d -name "${ARCH}*w64*" | head -n 1)"
		cp -r "$SRC_DIR/include" "$DST/usr/$TARGET/"
		cp -r "$SRC_DIR/lib" "$DST/usr/$TARGET/"

		# Strip static libs (optional)
		[ -z $STRIP ] && find "$DST/usr/$TARGET/lib" -name "*.a" -exec ${TARGET}-strip --strip-unneeded {} \; || true
		DEPS="mingw-w64-${DEB_ARCH}-dev"
		[ "$PKG" = "core" ] || DEPS="$DEPS, sdl2-mingw-w64-${DEB_ARCH}-dev"

		mkdir -p "$DST/DEBIAN"
		cat > "$DST/DEBIAN/control" <<EOF
Package: ${DEB_PKG}-mingw-w64-${DEB_ARCH}-dev
Version: $VER
Architecture: all
Maintainer: Auto Generated
Depends: $DEPS
Description: Precompiled ${LIBNAME} for MinGW-w64 ($ARCH)
EOF

		dpkg-deb --build "$DST" "../${DEB_PKG}-mingw-w64-${DEB_ARCH}-dev_${VER}.deb"
	done
)

printf "Created:"
for ARCH in $ARCHS; do
	DEB_ARCH=$(echo $ARCH | tr "_" "-")
	mv "$TMPDIR/../${DEB_PKG}-mingw-w64-${DEB_ARCH}-dev_${VER}.deb" .
	printf " ${DEB_PKG}-mingw-w64-${DEB_ARCH}-dev_${VER}.deb"
done
printf ".\n"

rm -Rf "$TMPDIR"


