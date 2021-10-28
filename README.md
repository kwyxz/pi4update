# pi4update

This is the script I use to keep my Raspberry-Pi-4-based bartop arcade.
Releasing it to the public in case there's interest, but with no warranty that it will work for you.

It will :
- update the system (Raspbian)
- download, build / update the tools
  - libretro cores
    - FBNeo
    - MAME 2003
    - PCSX ReARMed
    - NeoCD
  - RetroArch
  - Redream
  - SFML-Pi
  - Attract-Mode
 
As modern games in MAME / FBNeo tend to be unplayable on a Pi, using the console ports with their respective emulators allows running more recent 3D games. This means games ranging from Space Invaders to Ikaruga or Capcom vs. SNK 2.

This script was written for the Pi 4. The compilation options it uses probably won't work on another version of the Pi, but can probably be tweaked in order to do so.
