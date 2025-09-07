#!/usr/bin/env bash

### Configuration settings

# Repositories and URLs
SUPER_REPO="https://github.com/libretro/libretro-super.git"
FBNEO_REPO="https://github.com/libretro/FBNeo.git"
RA_REPO="https://github.com/libretro/RetroArch.git"
ATTRACT_REPO="https://github.com/oomek/attractplus.git"
HYPSEUS_REPO="https://github.com/DirtBagXon/hypseus-singe.git"
REDREAM_URL="https://redream.io/download"
# Paths
SHARE_PATH="/usr/local/share"
SRC_PATH="/usr/local/src"
RETRO_PATH="/usr/local/lib/libretro"
HYPSEUS_PATH="${SHARE_PATH}/hypseus"
REDREAM_TMP="/tmp/redream.tar.gz"
REDREAM_PATH="${SHARE_PATH}/redream"
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
    git clone --depth=1 --recursive "${2}" "${1}"
  fi
}

function copy_core {
  if [ -f ${1}_libretro.so ]; then
    cp ${1}_libretro.so "${SRC_PATH}/libretro-super/dist/unix/${1}_libretro.so"
  else
    print_c "error building ${1}"
  fi
}

function build_cores {
  sudo mkdir -p ${RETRO_PATH} && sudo chown root:adm ${RETRO_PATH} && sudo chmod 775 ${RETRO_PATH}
  for core in 'fbneo' 'mame2003_plus' 'neocd' 'pcsx_rearmed'; do
    mkdir -p /usr/local/lib/libretro
    print_y "* building ${core}"
    cd "${SRC_PATH}/libretro-super"
    case $core in
      'fbneo')
        git_dl "${SRC_PATH}/libretro-super/libretro-fbneo" "${FBNEO_REPO}"
        cd "${SRC_PATH}/libretro-super/libretro-fbneo/src/burner/libretro"
        make -j4 -f Makefile platform=rpi4_64
        copy_core ${core}
        ;;
      'pcsx_rearmed')
        ./libretro-fetch.sh "${core}"
        cd "${SRC_PATH}/libretro-super/libretro-${core}"
        make -j4 -f Makefile.libretro platform=rpi4_64
        copy_core ${core}
        ;; 
      *)
        ./libretro-fetch.sh ${core}
        ./libretro-build.sh ${core}
        ;;
    esac
    sudo install -m 0644 -t ${RETRO_PATH} "${SRC_PATH}/libretro-super/dist/info/${core}_libretro.info"
    sudo install -m 0755 -t ${RETRO_PATH} "${SRC_PATH}/libretro-super/dist/unix/${core}_libretro.so"
  done
  cd "$PWD"
}

function build_ra {
  print_y " * building RetroArch"
  sudo apt -y install libgles-dev libegl-dev libopengl-dev libgl-dev libasound2-dev libpipewire-0.3-dev libdrm-dev libfontconfig-dev libmbedtls-dev
  cd "${SRC_PATH}/retroarch"
  ./configure --disable-d3d9 --disable-d3dx --disable-dinput --disable-discord --disable-dsound --disable-ffmpeg --disable-gdi --disable-hid --disable-ibxm --disable-jack --disable-langextra --disable-materialui --disable-netplaydiscovery --disable-networkgamepad --disable-opengl --disable-opengl1 --disable-oss --disable-parport --disable-pulse --disable-qt --disable-rgui --disable-roar --disable-rsound --disable-runahead --disable-screenshots --disable-sdl --disable-sdl2 --disable-sixel --disable-ssa --disable-translate --disable-v4l2 --disable-vg --disable-videocore --disable-videoprocessor --disable-wasapi --disable-wayland --disable-winmm --disable-x11 --disable-xaudio --disable-xinerama --disable-xmb --disable-xrandr --disable-xshm --disable-xvideo --enable-kms --enable-opengl_core --enable-opengles --enable-opengles3 --enable-opengles3_1 --enable-plain_drm --disable-debug
  make -j4 && sudo make install
  cd "${PWD}"
}

function redream_update {
  print_y " * downloading Redream"
  rm -f ${REDREAM_TMP}
  sudo mkdir -p ${REDREAM_PATH}
  REDREAM_DEV="$(curl -s ${REDREAM_URL} | grep raspberry | grep -- "v.\..\..-.*-.*\.tar\.gz" | head -1 | cut -d '"' -f2 | cut -d '/' -f3)"
  curl -s ${REDREAM_URL}/${REDREAM_DEV} -o ${REDREAM_TMP}
  print_y "* installing Redream"
  sudo tar zxf ${REDREAM_TMP} -C ${REDREAM_PATH}/
  cd "${PWD}"
}

function build_hypseus {
  sudo apt -y install cmake libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libmpeg2-4-dev libzip-dev
  print_y " * building Hypseus Singe"
  sudo mkdir -p ${HYPSEUS_PATH}
  rm -rf "${SRC_PATH}/hypseus/build"
  cd "${SRC_PATH}/hypseus" && git checkout RetroPie
  mkdir -p "${SRC_PATH}/hypseus/build" && cd "${SRC_PATH}/hypseus/build"
  cmake ../src
  make -j4 && print_y "* installing Hypseus Singe" && sudo install -m 0755 -t /usr/local/bin/hypseus.bin ${SRC_PATH}/hypseus/build/hypseus
  rsync -avz --progress --inplace ${SRC_PATH}/hypseus/pics ${HYPSEUS_PATH}/
  rsync -avz --progress --inplace ${SRC_PATH}/hypseus/sound ${HYPSEUS_PATH}/ 
  rsync -avz --progress --inplace ${SRC_PATH}/hypseus/fonts ${HYPSEUS_PATH}/
  rm -rf ${HYPSEUS_PATH}/roms
  ln -sf ${HOME}/hypseus/roms ${HYPSEUS_PATH}/roms
  sudo install -m 0755 -t "${PWD}/hypseus_launcher.sh" /usr/local/bin/hypseus_launcher.sh
  sed -e 's,HYPSEUS_BIN=hypseus.bin,HYPSEUS_BIN=/usr/local/share/hypseus/hypseus,g' \
    -e 's,HYPSEUS_SHARE=~/.hypseus,HYPSEUS_SHARE=/usr/local/share/hypseus,g' \
    ${SRC_PATH}/hypseus/scripts/run.sh | sudo tee /usr/local/bin/hypseus
  sed -e 's,HYPSEUS_BIN=hypseus.bin,HYPSEUS_BIN=/usr/local/share/hypseus/hypseus,g' \
    -e 's,HYPSEUS_SHARE=~/.hypseus,HYPSEUS_SHARE=/usr/local/share/hypseus,g' \
    ${SRC_PATH}/hypseus/scripts/singe.sh | sudo tee /usr/local/bin/singe
  sudo chmod 755 /usr/local/bin/hypseus /usr/local/bin/singe
  cd "${PWD}"
}

#function build_sfml {
#  print_y " * building SFML"
#  rm -rf "${SRC_PATH}/sfml-pi/build" && mkdir -p "${SRC_PATH}/sfml-pi/build"
#  cd "${SRC_PATH}/sfml-pi/build/"
#  cmake .. -DSFML_DRM=1 -DOpenGL_GL_PREFERENCE=GLVND && sudo make install && sudo ldconfig
#  cd "${PWD}"
#}

function build_attract {
  sudo apt -y install libexpat1-dev
  print_y " * building Attract-Mode Plus"
  cd "${SRC_PATH}/attractplus"
  make clean
  make -j4 USE_DRM=1 && sudo make install USE_DRM=1
  cd "${PWD}"
}

function tools_update {
  sudo apt -y install armv8-support build-essential git pipewire rsync wireplumber
  sudo apt -y install raspi-config raspi-firmware rpi-audio-utils rpi-splash-screen-support
  # removed 'sfml-pi' from the list as it's part of attractplus now
  for src in 'libretro-super' 'retroarch' 'redream' 'hypseus' 'attractplus'; do
    print_b "=> ${src}"
    case ${src} in
      'libretro-super')
        git_dl "${SRC_PATH}/${src}" "${SUPER_REPO}"
        build_cores
        ;;
      'retroarch')
        git_dl "${SRC_PATH}/${src}" "${RA_REPO}"
        build_ra
        ;;
      'redream')
        redream_update
        ;;
      'hypseus')
        git_dl "${SRC_PATH}/${src}" "${HYPSEUS_REPO}"
        build_hypseus
        ;;
      'attractplus')
        git_dl "${SRC_PATH}/${src}" "${ATTRACT_REPO}"
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
