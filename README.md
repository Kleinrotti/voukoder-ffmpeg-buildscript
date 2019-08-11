# voukoder-ffmpeg-buildscript

Builds static libraries of ffmeg and external libraries (x264 8bit, x265 8,10 and 12bit) to be used in the voukoder project.

## Install msys2
- Get the 64bit version of msys2 from msys2.org
- Install it

## Start msys2
- Open a command prompt
- Run "vcvarsall.bat amd64" in "c:\program files (x86)\microsoft visual studio\2017\community\VC\Auxiliary\Build"
- Run x64 native command promt and start msys2 with "msys2_shell.cmd -mingw64 -full-path"

## Install development tools
- Install CMakeGui in Windows to have the VisualStudio templates ready
- Install "pacman -S base-devel binutils git make pkg-config" in msys2
- Add cmake path to path variable
- To compile libvpx: 
         For Visual Studio the base yasm binary (not vsyasm) should be in the
         PATH for Visual Studio. For VS2017 it is sufficient to rename
         yasm-<version>-<arch>.exe to yasm.exe and place it in:
         Program Files (x86)/Microsoft Visual Studio/2017/<level>/Common7/Tools/
- To compile libmfx:
         Get nasm from [here](https://github.com/ShiftMediaProject/VSNASM) and execute the install script
         Ensure that you add nasm to path variable
- Check for right paths with the command: 'which nasm yasm link cl' if the paths pointing to the visual studio directory every thing is       fine

## Starting the build
- Start the script with e.g. './build_tc.sh clone' to clone the repos
- Compile the needed libraries with e.g. './build_tc.sh all debug' or replace 'all' with the specific library name
