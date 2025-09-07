#!/usr/bin/env bash

GAME=$(basename ${1} .zip)

case ${GAME} in
  ace|astron|badlands|bega|cliff|cobra|esh|galaxy|gpworld|interstellar|lair|lair2|mach3|roadblaster|sdq|tq|uvt)
    /usr/local/bin/hypseus ${GAME}
    ;;
  timegal|hayate)
    /usr/local/bin/singe ${GAME}
    ;;
  *)
    die "this game is not available"
    ;;
esac
