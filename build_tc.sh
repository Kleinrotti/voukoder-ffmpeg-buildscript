#!/bin/bash

STEP=$1
MODE=$2
CPU_CORES=$3
SRC=`realpath src`
BUILD=`realpath build`
VSVERSION="Visual Studio 16 2019"
svtvp9="https://github.com/OpenVisualCloud/SVT-VP9.git"
svtav1="https://github.com/OpenVisualCloud/SVT-AV1.git"
svthevc="https://github.com/OpenVisualCloud/SVT-HEVC.git"
opus="https://git.xiph.org/opus.git"
fdkaac="https://github.com/mstorsjo/fdk-aac.git"
libmp3lame="https://github.com/gypified/libmp3lame.git"
zimg="https://github.com/sekrit-twc/zimg.git"
x265="https://github.com/videolan/x265.git"
x264="https://code.videolan.org/videolan/x264.git"
libogg="https://github.com/xiph/ogg.git"
libvorbis="https://github.com/xiph/vorbis.git"
libvpx="https://github.com/webmproject/libvpx.git"
snappy="https://github.com/google/snappy.git"
libaom="https://aomedia.googlesource.com/aom"
ffmpeg="https://github.com/FFmpeg/FFmpeg.git"
amf="https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git"
ffnvcodec="https://github.com/FFmpeg/nv-codec-headers.git"
libmfx="https://github.com/Intel-Media-SDK/MediaSDK.git"

function compile_all {
  compile_libaom
  compile_libmfx
  compile_libmp3lame
  compile_libogg
  compile_libvorbis
  compile_libvpx
  compile_opus
  compile_fdk-aac
  compile_snappy
  compile_x264
  compile_x265
  compile_zimg
  compile_svt-av1
}

function create_builddirs {
  [ ! -d "$BUILD" ] && mkdir $BUILD
  [ ! -d "$BUILD/include" ] && mkdir $BUILD/include
  [ ! -d "$BUILD/lib" ] && mkdir $BUILD/lib
  [ ! -d "$BUILD/lib/pkgconfig" ] && mkdir $BUILD/lib/pkgconfig
}

function clone_all {
  git clone $zimg $SRC/zimg &
  git clone $x264 $SRC/x264 &
  git clone $x265 --branch stable $SRC/x265 &
  git clone $libvpx $SRC/libvpx &
  git clone $libmfx $SRC/libmfx &
  git clone $libvorbis $SRC/libvorbis &
  git clone $libmp3lame $SRC/lame
  git clone $opus $SRC/opus &
  git clone $fdkaac $SRC/fdk-aac &
  git clone $snappy $SRC/snappy &
  git clone $ffmpeg --branch release/4.2 $SRC/ffmpeg &
  git clone $svtav1 $SRC/svt-av1 &
  git clone $svtvp9 $SRC/svt-vp9 &
  git clone $svthevc $SRC/svt-hevc &
  git clone $libogg $SRC/libogg &
  git clone $libaom $SRC/libaom &
  git clone $amf $SRC/amf
  git clone $ffnvcodec $SRC/ffnvcodec
}

function compile {
  cd $SRC/$1
  if [ -f autogen.sh ]; then
    ./autogen.sh
  fi
  CC=cl CXXFLAGS=$CFLAGS ./configure --prefix=$BUILD $2
  make -j $CPU_CORES
  make install
}

function compile_svt-av1 {
  echo "#### COMPILING SVT-AV1 ..."
  cd $SRC/svt-av1/Build
  cmake .. -G "$VSVERSION" -A x64 -DCMAKE_INSTALL_PREFIX=$BUILD -DCMAKE_CONFIGURATION_TYPES="Debug;Release"
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" /property:ConfigurationType="StaticLibrary" /property:TargetExt=".lib" Source/Lib/Encoder/SvtAv1Enc.vcxproj
  cp -r ../Source/API $BUILD/include/svt-av1
  cp ../Bin/Release/$MSBUILD_CONFIG/SvtAv1Enc.lib $BUILD/lib/
  cp SvtAv1Enc.pc $BUILD/lib/pkgconfig/
}

function compile_libmfx {
  echo "#### COMPILING LIBMFX ..."
  cd $SRC/libmfx/api/mfx_dispatch/windows
  if [ "$MODE" == "debug" ];then
    MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" /property:OutDir="$(ProjectDir)..\..\..\build/" /property:RuntimeLibrary=MultiThreadedDebug /property:WindowsTargetPlatformVersion=10.0.18362.0 /property:PlatformToolset=v142 /property:Platform=x64 libmfx_vs2015.vcxproj
  else
    MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" /property:OutDir="$(ProjectDir)..\..\..\build/" /property:WindowsTargetPlatformVersion=10.0.18362.0 /property:PlatformToolset=v142 /property:Platform=x64 libmfx_vs2015.vcxproj
  fi
  cp $SRC/libmfx/build/libmfx_vs2015.lib $BUILD/lib/libmfx.lib
  cp -r ../../include $BUILD/include/mfx
}

function compile_opus {
  echo "#### COMPILING OPUS ..."
  cd $SRC/opus/win32/VS2015
  echo \nConverting project file ...
  sed -i 's/v140/v141/v142g' opus.vcxproj
  echo Building project 'opus' ...
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" /property:WindowsTargetPlatformVersion=10.0.18362.0 /property:PlatformToolset=v142 /property:Platform=x64 opus.vcxproj
  echo Done.
  cp x64/$MSBUILD_CONFIG/opus.lib $BUILD/lib/opus.lib
  cp -r $SRC/opus/include $BUILD/include/opus
  cp $SRC/opus/opus.pc.in $BUILD/lib/pkgconfig/opus.pc
  sed -i "s#@prefix@#$BUILD#g" $BUILD/lib/pkgconfig/opus.pc
  sed -i "s/@exec_prefix@/\$\{prefix\}/g" $BUILD/lib/pkgconfig/opus.pc
  sed -i "s/@libdir@/\$\{prefix\}\/lib/g" $BUILD/lib/pkgconfig/opus.pc
  sed -i "s/@includedir@/\$\{prefix\}\/include/g" $BUILD/lib/pkgconfig/opus.pc
  sed -i "s/@LIBM@//g" $BUILD/lib/pkgconfig/opus.pc
  sed -i "s/@VERSION@/2.0.0/g" $BUILD/lib/pkgconfig/opus.pc
}

function compile_zimg {
  echo "#### COMPILING ZIMG ..."
  cd $SRC/zimg
  ./autogen.sh
  ./configure --prefix=$BUILD
  cd _msvc/zimg
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" /property:ConfigurationType=StaticLibrary /property:WindowsTargetPlatformVersion=10.0.18362.0 /property:PlatformToolset=v142 /property:Platform=x64 /property:WholeProgramOptimization=false zimg.vcxproj
  cp x64/$MSBUILD_CONFIG/z.lib $BUILD/lib/zimg.lib
  cd ../..
  cp src/zimg/api/zimg.h  $BUILD/include/zimg.h
  cp zimg.pc $BUILD/lib/pkgconfig/zimg.pc
}

function compile_fdk-aac {
  echo "#### COMPILING FDK-AAC ..."
  compile fdk-aac "--disable-static --disable-shared"
}

function compile_snappy {
  echo "#### COMPILING SNAPPY ..."
  cd $SRC/snappy
  rm -rf work
  mkdir work
  cd work
  cmake -G "$VSVERSION" .. -DCMAKE_INSTALL_PREFIX=$BUILD -DBUILD_SHARED_LIBS=OFF -DSNAPPY_BUILD_TESTS=OFF
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" Snappy.sln
  cp $MSBUILD_CONFIG/snappy.lib $BUILD/lib/snappy.lib
  cp ../snappy.h ../snappy-c.h $BUILD/include/
}

function compile_x264 {
  echo "#### COMPILING X264 ..."
  cd $SRC/x264
  CC=cl ./configure --prefix=$BUILD --extra-cflags='-DNO_PREFIX' --disable-cli --enable-static --libdir=$BUILD/lib
  make -j $CPU_CORES
  make install-lib-static
}

function compile_x265 {
  echo "#### COMPILING X265 ..."
  # checkout manually (cmake is getting values from git)
  cd $src/..
  if [ ! -d $SRC/x265/.git ]; then
    git clone https://github.com/videolan/x265.git --branch stable $SRC/x265
  fi
  git reset --hard
  git pull
  cd $SRC/x265/build/vc15-x86_64
  rm -rf work*
  mkdir work work10 work12
  # 12bit
  cd work12
  cmake -G "$VSVERSION" ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" x265-static.vcxproj
  cp $MSBUILD_CONFIG/x265-static.lib ../work/x265_12bit.lib
  # 10bit
  cd ../work10
  cmake -G "$VSVERSION" ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" x265-static.vcxproj
  cp $MSBUILD_CONFIG/x265-static.lib ../work/x265_10bit.lib
  # 8bit - main
  cd ../work
  cmake -G "$VSVERSION" ../../../source -DCMAKE_INSTALL_PREFIX=$BUILD -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DEXTRA_LIB="x265_10bit.lib;x265_12bit.lib" -DLINKED_10BIT=ON -DLINKED_12BIT=ON
  #-DSTATIC_LINK_CRT=ON
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" x265-static.vcxproj
  cp $MSBUILD_CONFIG/x265-static.lib ./x265_main.lib
  LIB.EXE /ignore:4006 /ignore:4221 /OUT:x265.lib x265_main.lib x265_10bit.lib x265_12bit.lib
  cp x265.lib $BUILD/lib/x265.lib
  cp x265.pc $BUILD/lib/pkgconfig/x265.pc
  cp x265_config.h $BUILD/include/
  cp ../../../source/x265.h $BUILD/include/
}

function compile_libaom {
  echo "#### COMPILING LIBAOM ..."
  cd $SRC/libaom
  rm -rf work
  mkdir work
  cd work
  cmake -G "$VSVERSION" .. -DENABLE_{DOCS,TOOLS,TESTS}=off -DAOM_TARGET_CPU=x86_64 -DCMAKE_INSTALL_PREFIX=$BUILD
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" AOM.sln
  cp $MSBUILD_CONFIG/aom.lib $BUILD/lib/aom.lib
  cp -r ../aom $BUILD/include/aom
  cmake -AOM_CONFIG_DIR=. -AOM_ROOT=.. -DCMAKE_INSTALL_PREFIX=@prefix@ -DCMAKE_PROJECT_NAME=aom -DCONFIG_MULTITHREAD=true -DHAVE_PTHREAD_H=false -P "../build/cmake/pkg_config.cmake"
  sed -i "s#@prefix@#$BUILD#g" aom.pc
  sed -i '/^Libs\.private.*/d' aom.pc
  sed -i 's/-lm//' aom.pc
  cp aom.pc $BUILD/lib/pkgconfig/aom.pc
}

function compile_libmp3lame {
  echo "#### COMPILING LIBMP3LAME ..."
  compile lame "--enable-nasm --disable-frontend --disable-shared --enable-static"
  cp $BUILD/lib/libmp3lame.lib $BUILD/lib/mp3lame.lib
  rm $BUILD/lib/libmp3lame.lib
}

function compile_libogg {
  echo "#### COMPILING LIBOGG ..."
  compile libogg "--disable-shared"
}

function compile_libvorbis {
  echo "#### COMPILING LIBVORBIS ..."
  cp -ar $SRC/libogg/include/ogg/ $SRC/libvorbis/lib/ #copying needed ogg files
  compile libvorbis "--disable-shared"  
  sed -i '/^Libs\.private.*/d' $BUILD/lib/pkgconfig/vorbis.pc  # don't need m.lib on windows
}

function compile_libvpx {
  echo "#### COMPILING LIBVPX ..."
  cd $SRC/libvpx
  ./configure --prefix=$BUILD --target=x86_64-win64-vs15 --enable-vp9-highbitdepth --disable-shared --disable-examples --disable-tools --disable-docs --disable-libyuv --disable-unit_tests --disable-postproc
  make -j $CPU_CORES
  MSBuild.exe /maxcpucount:$CPU_CORES /property:Configuration="$MSBUILD_CONFIG" /property:TargetName=vpx /property:PostBuildEventUseInBuild=false /property:OutDir=$(ProjectDir)msvc/ /property:WindowsTargetPlatformVersion=10.0.18362.0 /property:PlatformToolset=v142 /property:Platform=x64 vpx.vcxproj
  cp $SRC/libvpx/msvc/vpx.lib $BUILD/lib/vpx.lib
  cp -r $SRC/libvpx/vpx $BUILD/include
}

function compile_ffmpeg {
  cd $SRC/ffmpeg
  make clean
  echo "### Copying NVENC headers ..."
  cd $SRC/ffnvcodec
  make PREFIX=$BUILD install
  
  echo "### Copying AMF headers ..."
  cp -a $SRC/amf/amf/public/include $BUILD/include/AMF
  
  echo "### Applying patches ..."
  cd $SRC/ffmpeg
  patch -N -p1 -i ../svt-av1/ffmpeg_plugin/0001-Add-ability-for-ffmpeg-to-run-svt-av1.patch
  ffbranch=$(git rev-parse --abbrev-ref HEAD)
  echo "FFMpeg branch: $ffbranch ..."
  if [ "$ffbranch" == "release/4.0" ]; then
    patch -N -p1 -i ../../patches/0001-dynamic-loading-of-shared-fdk-aac-library-4.0.patch
    patch -N -p0 -i ../../patches/0002-patch-ffmpeg-to-new-fdk-api.patch
  else  
    patch -N -p1 -i ../../patches/0001-dynamic-loading-of-shared-fdk-aac-library.patch
  fi
  
  echo "### Compiling FFMpeg ..."
  cd $SRC/ffmpeg
  PKG_CONFIG_PATH=$BUILD/lib/pkgconfig:$PKG_CONFIG_PATH ./configure --toolchain=msvc --extra-cflags="$CFLAGS -I$BUILD/include" --extra-ldflags="-LIBPATH:$BUILD/lib" --prefix=$BUILD --pkg-config-flags="--static" --disable-doc --disable-shared --enable-static --enable-gpl --enable-nonfree --enable-runtime-cpudetect --disable-devices --disable-network --enable-w32threads --enable-postproc --enable-libsnappy --enable-libmp3lame --enable-libsvtav1 --enable-libzimg --enable-avisynth --enable-libx265 --enable-cuda --enable-cuvid --enable-d3d11va --enable-nvenc --enable-libvpx --enable-libvorbis --enable-libmfx --enable-libopus --enable-amf --enable-libfdk-aac
  make -j $CPU_CORES
  make install
  
  # rename *.a to *.lib
  cd $BUILD/lib
  for file in *.a; do
    mv "$file" "`basename "$file" .a`.lib"
  done
  
  # Create archives
  cd $BUILD
  mkdir ../dist 2>/dev/null
  tar czf ../dist/ffmpeg-win64-static-$MODE.tar.gz *
  #cd $SRC/ffmpeg
  #tar czf ../../dist/ffmpeg-win64-static-src-$MODE.tar.gz *
}

function print_help {
  echo "Parameters which can be used"
  echo "First parameter:"
  echo "clone|clean_sources|<package to compile>"
  echo "Second paramter is only needed when compiling a package (build mode):"
  echo "release|debug"
  echo "Third parameter is fully optional and sets the CPU core number when compiling"
}

if [ "$MODE" == "debug" ]; then
  MSBUILD_CONFIG=Debug
  CFLAGS=-MDd
  create_builddirs
elif [ "$MODE" == "release" ]; then
  MSBUILD_CONFIG=Release
  CFLAGS=-MD
  create_builddirs
elif [ "$STEP" == "clone" ]; then
  echo "#### CLONING ..."
elif [ "$STEP" == "clean" ]; then
  echo "#### CLEANING ..."
elif [ "$STEP" == "-h" ]; then
  print_help
  exit 0
else
  echo "Please supply build mode [debug|release]!"
  exit 1
fi

if [ -z "$CPU_CORES" ]; then
  CPU_CORES=$(nproc --all)
fi

if [ "$STEP" == "svt-av1" ]; then
  compile_svt-av1
elif [ "$STEP" == "all" ]; then
  compile_all
elif [ "$STEP" == "clean" ]; then
  rm -rf $SRC
  cd $BUILD
  rm -rf ../dist
  rm -rf $BUILD
  mkdir $SRC
elif [ "$STEP" == "clone" ]; then
  clone_all
elif [ "$STEP" == "libmfx" ]; then
  compile_libmfx
elif [ "$STEP" == "opus" ]; then
  compile_opus
elif [ "$STEP" == "libfdk-aac" ]; then
  compile_fdk-aac
elif [ "$STEP" == "lame" ]; then
  compile_libmp3lame
elif [ "$STEP" == "zimg" ]; then
  compile_zimg
elif [ "$STEP" == "x264" ]; then
  compile_x264
elif [ "$STEP" == "x265" ]; then
  compile_x265
elif [ "$STEP" == "libogg" ]; then
  compile_libogg
elif [ "$STEP" == "libvorbis" ]; then
  compile_libvorbis
elif [ "$STEP" == "libvpx" ]; then
  compile_libvpx
elif [ "$STEP" == "snappy" ]; then
  compile_snappy
elif [ "$STEP" == "libaom" ]; then
  compile_libaom
elif [ "$STEP" == "ffmpeg" ]; then
  compile_ffmpeg
else
  echo "Unknown build step!"
  exit 1
fi
