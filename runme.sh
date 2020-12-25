#!/usr/bin/env bash

### Configuration settings

SUPER_REPO="https://github.com/libretro/libretro-super.git"
FBNEO_REPO="https://github.com/kwyxz/FBNeo.git"
RA_REPO="https://github.com/libretro/RetroArch.git"
SFML_REPO="https://github.com/mickelson/sfml-pi.git"
ATTRACT_REPO="https://github.com/mickelson/attract.git"
SRCPATH="/usr/local/src"
RETROPATH="/usr/local/lib/libretro"
PWD="$(pwd)"

### Generic functions

function print_c {
  printf "\e[1;${1}m%s\e[0m\n" "${2}"
}

function print_r {
  print_c "31" "${1}"
}

function print_g {
  print_c "32" "${1}"
}

function print_y {
  print_c "33" "${1}"
}

function print_b {
  print_c "34" "${1}"
}

function die {
  print_r "ERROR: ${1}"
  exit 1
}

### Pi4 specific functions

function raspbian_update {
  sudo apt -y update && sudo apt -y full-upgrade
}

function git_dl {
  print_y " * updating source code $1"
  if [ -d "${1}" ]; then
    git -C "${1}" pull --recurse-submodules
  else
    git clone --recursive "${2}" "${1}"
  fi
}

function copy_core {
  if [ -f ./${1}_libretro.so ]; then
    cp ${1}_libretro.so "${SRCPATH}/libretro-super/dist/unix/"
  else
    print_c "error building ${1}"
  fi
}

function build_cores {
  for core in 'fbneo' 'mame2003_plus' 'neocd' 'pcsx_rearmed'; do
    cd "${SRCPATH}/libretro-super"
    case $core in
      'fbneo')
        git_dl "${SRCPATH}/libretro-super/libretro-fbneo" "${FBNEO_REPO}"
        cd "${SRCPATH}/libretro-super/libretro-fbneo/src/burner/libretro"
        make -f Makefile platform=rpi4
        copy_core ${core}
        ;;
      'pcsx_rearmed')
        ./libretro-fetch.sh "${core}"
        cd "${SRCPATH}/libretro-super/libretro-${core}"
        make -f Makefile.libretro platform=rpi4
        copy_core ${core}
        ;; 
      *)
        ./libretro-fetch.sh "${core}"
        ./libretro-build.sh "${core}"
        ;;
    esac
    sudo install -m 0644 -t ${RETROPATH} "${SRCPATH}/libretro-super/dist/info/${core}_libretro.info"
    sudo install -m 0755 -t ${RETROPATH} "${SRCPATH}/libretro-super/dist/unix/${core}_libretro.so"
  done
  cd "$PWD"
}

function build_ra {
  print_y " * building"
  cd "${SRCPATH}/retroarch"
  ./configure --disable-d3d9 --disable-d3dx --disable-dinput --disable-discord --disable-dsound --disable-ffmpeg --disable-gdi --disable-hid --disable-ibxm --disable-jack --disable-langextra --disable-materialui --disable-miniupnpc --disable-netplaydiscovery --disable-networkgamepad --disable-networking --disable-online_updater --disable-opengl --disable-opengl1 --disable-oss --disable-parport --disable-pulse --disable-qt --disable-rgui --disable-roar --disable-rsound --disable-runahead --disable-screenshots --disable-sdl --disable-sdl2 --disable-sixel --disable-ssa --disable-translate --disable-v4l2 --disable-vg --disable-videocore --disable-videoprocessor --disable-wasapi --disable-wayland --disable-winmm --disable-x11 --disable-xaudio --disable-xinerama --disable-xmb --disable-xrandr --disable-xshm --disable-xvideo --enable-kms --enable-opengl_core --enable-opengles --enable-opengles3 --enable-plain_drm --enable-debug
  make && sudo make install
  cd "${PWD}"
}

function build_sfml {
  print_y " * building"
  mkdir -p "${SRCPATH}/sfml-pi/build"
  cd "${SRCPATH}/sfml-pi/build/"
  cmake .. -DSFML_DRM=1
  sudo make install
  sudo ldconfig
  cd "${PWD}"
}

function build_attract {
  print_y " * building"
  cd "${SRCPATH}/attract"
  make USE_DRM=1 USE_MMAL=1
  sudo make install USE_DRM=1 USE_MMAL=1
  cd "${PWD}"
}

function tools_update {
  for src in 'libretro-super' 'retroarch' 'sfml-pi' 'attract'; do
    print_b "=> ${src}"
    case ${src} in
      'libretro-super')
        git_dl "${SRCPATH}/${src}" "${SUPER_REPO}"
        build_cores
        ;;
      'retroarch')
        git_dl "${SRCPATH}/${src}" "${RA_REPO}"
        build_ra
        ;;
      'sfml-pi')
        git_dl "${SRCPATH}/${src}" "${SFML_REPO}"
        build_sfml
        ;;
      'attract')
        git_dl "${SRCPATH}/${src}" "${ATTRACT_REPO}"
        build_attract
        ;;
      *)
        die "This should never happen"
        ;;
    esac
  done
}

### Main script

print_g "1. System"
raspbian_update
print_g "2. Tools"
tools_update
print_g "3. All done"
