#!/bin/sh

set -ex
ARCH="$(uname -m)"
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

pacman -Syu --noconfirm \
	base-devel          \
	boost               \
	boost-libs          \
	catch2              \
	cmake               \
	curl                \
	enet                \
	fmt                 \
	gamemode            \
	gcc                 \
	git                 \
	libxi               \
	libxkbcommon-x11    \
	libxss              \
	llvm                \
	llvm-libs           \
	lz4                 \
	mbedtls2            \
	mesa                \
	ninja               \
	nlohmann-json       \
	openal              \
	pipewire-audio      \
	pulseaudio          \
	pulseaudio-alsa     \
	qt6-base            \
	qt6ct               \
	qt6-multimedia      \
	qt6-tools           \
	qt6-wayland         \
	sdl2                \
	unzip               \
	vulkan-headers      \
	vulkan-mesa-layers  \
	wget                \
	xcb-util-cursor     \
	xcb-util-image      \
	xcb-util-renderutil \
	xcb-util-wm         \
	xorg-server-xvfb    \
	zip                 \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-mesa qt6-base-mini llvm-libs-nano opus-nano

echo "Building citron..."
echo "---------------------------------------------------------------"

if [ "$1" = 'v3' ] && [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64-v3 optimized build of citron..."
	ARCH_FLAGS="-march=x86-64-v3 -O3"
elif [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64 generic build of citron..."
	ARCH_FLAGS="-march=x86-64 -mtune=generic -O3"
else
	echo "Making aarch64 build of citron..."
	ARCH_FLAGS="-march=armv8-a -mtune=generic -O3"
fi

if [ "$DEVEL" = 'true' ]; then
	echo "Making nightly build..."
else
	echo "Making stable build..."
fi

# Clone repository with submodules
git clone --recursive --depth 1 https://git.citron-emu.org/citron/emulator.git ./citron
cd ./citron

# Configure CMake build
mkdir -p build
cd build

cmake .. \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_CXX_FLAGS="$ARCH_FLAGS" \
	-DCMAKE_C_FLAGS="$ARCH_FLAGS" \
	-DDISCORD_PRESENCE=OFF \
	-DUSE_QT_MULTIMEDIA=OFF \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_DISABLE_FIND_PACKAGE_Git=ON \
	-DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=ON \
	-DCMAKE_SKIP_INSTALL_RPATH=ON \
	-DCMAKE_SKIP_RPATH=ON \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=OFF \
	-DCMAKE_VERBOSE_MAKEFILE=OFF \
	-DCMAKE_COLOR_MAKEFILE=OFF

make -j$(nproc)
make install DESTDIR=/tmp/citron-install

# Create version file
if [ "$DEVEL" = 'true' ]; then
	git rev-parse --short HEAD > ~/version
else
	git describe --tags --abbrev=0 > ~/version
fi

# Install to system
cp -r /tmp/citron-install/* /
