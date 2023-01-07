#!/usr/bin/env bash

SCRIPT_HOME=$(pwd)
HYPSEUS_HOME='/usr/local/lib/hypseus'
GLOBAL_OPTIONS="vldp -homedir ${HYPSEUS_HOME} -datadir ${HYPSEUS_HOME} -opengl"

function print_c {
  printf "\e[1;${1}m%s\e[0m\n" "${2}"
}

function print_r {
  print_c "31" "${1}"
}

function die {
  print_r "ERROR: ${1}"
  exit 1
}

function run_game {
  case $2 in
    singe)
      ${HYPSEUS_HOME}/hypseus ${2} ${GLOBAL_OPTIONS} -framefile ${HYPSEUS_HOME}/${2}/${1}-hd/${1}-hd.txt -script ${HYPSEUS_HOME}/${2}/${1}-hd/${1}-hd.singe
      ;;
    *)
      ${HYPSEUS_HOME}/hypseus ${1} ${GLOBAL_OPTIONS} -framefile ${HYPSEUS_HOME}/${2}/${1}/${1}.txt
    ;;
  esac
}

if [ $# -ne 1 ]; then
  die "you need to enter exactly one argument"
fi

GAME=$(basename ${1} .zip)

case ${GAME} in
  ace|lair|lair2|tq)
    run_game ${GAME} vldp_dl
    ;;
  astron|badlands|bega|cliff|cobra|esh|galaxy|gpworld|interstellar|mach3|roadblaster|sdq|uvt)
    run_game ${GAME} vldp
    ;;
  timegal|hayate)
    run_game ${GAME} singe
    ;;
  *)
    die "this game is not available"
    ;;
esac
