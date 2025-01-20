#!/bin/bash
#  Builds xcframework for current iPhone targets: iPhoneOS-arm64, iPhoneSimulator-x86_64, 
#  and iPhoneSimulator-arm64. 
#
#  Copyright 2012 Mike Tigas <mike@tig.as>
#
#  Based on work by Felix Schulze on 16.12.10.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Choose your libopus version and your currently-installed iOS SDK version:
#
VERSION="1.4"
SDKVERSION="18.2"
MIN_VERSION="14.0"

###########################################################################
#
# Don't change anything under this line!
#
###########################################################################

# by default, we won't build for debugging purposes
if [ "${DEBUG}" == "true" ]; then
    echo "Compiling for debugging ..."
    OPT_CFLAGS="-O0 -fno-inline -g"
    OPT_LDFLAGS=""
    OPT_CONFIG_ARGS="--enable-assertions --disable-asm"
else
    OPT_CFLAGS="-Ofast -flto -g"
    OPT_LDFLAGS="-flto"
    OPT_CONFIG_ARGS=""
fi


# No need to change this since xcode build will only compile in the
# necessary bits from the libraries we create
SIMULATOR_ARCHS="x86_64 arm64"
ARCHS="arm64"

DEVELOPER=`xcode-select -print-path`
#DEVELOPER="/Applications/Xcode.app/Contents/Developer"

cd "`dirname \"$0\"`"
REPOROOT=$(pwd)

# Where we'll end up storing things in the end
OUTPUTDIR="${REPOROOT}/dependencies"
mkdir -p ${OUTPUTDIR}/include
mkdir -p ${OUTPUTDIR}/lib


BUILDDIR="${REPOROOT}/build"

# where we will keep our sources and build from.
SRCDIR="${BUILDDIR}/src"
mkdir -p $SRCDIR
# where we will store intermediary builds
INTERDIR="${BUILDDIR}/built"
mkdir -p $INTERDIR

########################################

cd $SRCDIR

# Exit the script if an error happens
set -e

if [ ! -e "${SRCDIR}/opus-${VERSION}.tar.gz" ]; then
	echo "Downloading opus-${VERSION}.tar.gz"
	curl -LO http://downloads.xiph.org/releases/opus/opus-${VERSION}.tar.gz
fi
echo "Using opus-${VERSION}.tar.gz"

tar zxf opus-${VERSION}.tar.gz -C $SRCDIR
cd "${SRCDIR}/opus-${VERSION}"

set +e # don't bail out of bash script if ccache doesn't exist
CCACHE=`which ccache`
if [ $? == "0" ]; then
	echo "Building with ccache: $CCACHE"
	CCACHE="${CCACHE} "
else
	echo "Building without ccache"
	CCACHE=""
fi
set -e # back to regular "bail out on error" mode

export ORIGINALPATH=$PATH

# Build the static library for the simulator

for ARCH in ${SIMULATOR_ARCHS}
do
	PLATFORM="iPhoneSimulator"
    EXTRA_CFLAGS="-arch ${ARCH}"
    if [ "${ARCH}" == "x86_64" ]; then        
        EXTRA_CONFIG="--host=x86_64-apple-darwin"
    else
        EXTRA_CONFIG="--host=arm-apple-darwin"
    fi

	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

	./configure --enable-float-approx --disable-shared --enable-static --with-pic --disable-extra-programs --disable-doc ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -miphonesimulator-version-min=${MIN_VERSION} -L${OUTPUTDIR}/lib" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -miphonesimulator-version-min=${MIN_VERSION} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \

    # Build the application and install it to the fake SDK intermediary dir
    # we have set up. Make sure to clean up afterward because we will re-use
    # this source tree to cross-compile other targets.
	make -j4
	make install
	make clean
done

########################################

echo "Build simulator library..."

# These are the libs that comprise libopus.
OUTPUT_LIB="libopus.a"

INPUT_LIBS=""
for ARCH in ${SIMULATOR_ARCHS}; do
	PLATFORM="iPhoneSimulator"
	INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
	if [ -e $INPUT_ARCH_LIB ]; then
		INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
	fi
done
# Combine the three architectures into a universal library.
if [ -n "$INPUT_LIBS"  ]; then
	lipo -create $INPUT_LIBS \
	-output "${OUTPUTDIR}/lib/${OUTPUT_LIB}"
else
	echo "$OUTPUT_LIB does not exist, skipping (are the dependencies installed?)"
fi

for ARCH in ${SIMULATOR_ARCHS}; do
	PLATFORM="iPhoneSimulator"
	cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/* ${OUTPUTDIR}/include/
	if [ $? == "0" ]; then
		# We only need to copy the headers over once. (So break out of forloop
		# once we get first success.)
		break
	fi
done


####################

# Create xcarchive for the simulator
SCHEME="OpusKit"
ARCHIVE_DIR="${OUTPUTDIR}/archives"
SIMULATOR_ARCHIVE_PATH="${ARCHIVE_DIR}/${SCHEME}-iphonesimulator.xcarchive"
DEVICE_ARCHIVE_PATH="${ARCHIVE_DIR}/${SCHEME}-iphoneos.xcarchive"

mkdir -p $ARCHIVE_DIR

# Simulator xcarchive (arm64 + x86_64)
echo $(pwd)
cd "${REPOROOT}/opus"
xcodebuild archive \
  ONLY_ACTIVE_ARCH=NO \
  -scheme "${SCHEME}" \
  -project "${SCHEME}.xcodeproj" \
  -archivePath ${SIMULATOR_ARCHIVE_PATH} \
  -sdk iphonesimulator \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO
cd "${SRCDIR}/opus-${VERSION}"

# Remove the intermediate files from the simulator build
rm -fr ${INTERDIR}
# Remove the simulator static library
rm "${OUTPUTDIR}/lib/${OUTPUT_LIB}"


####################

# Build the static library for the device

for ARCH in ${ARCHS}
do
	PLATFORM="iPhoneOS"
    EXTRA_CFLAGS="-arch ${ARCH}"
    EXTRA_CONFIG="--host=arm-apple-darwin"

	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

	./configure --enable-float-approx --disable-shared --enable-static --with-pic --disable-extra-programs --disable-doc ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -miphoneos-version-min=${MIN_VERSION} -L${OUTPUTDIR}/lib" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -miphoneos-version-min=${MIN_VERSION} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \

    # Build the application and install it to the fake SDK intermediary dir
    # we have set up. Make sure to clean up afterward because we will re-use
    # this source tree to cross-compile other targets.
	make -j4
	make install
	make clean
done

########################################

echo "Build device library..."

# These are the libs that comprise libopus.
INPUT_LIBS=""
for ARCH in ${ARCHS}; do
	PLATFORM="iPhoneOS"
	INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
	if [ -e $INPUT_ARCH_LIB ]; then
		INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
	fi
done
# Combine the three architectures into a universal library.
if [ -n "$INPUT_LIBS"  ]; then
	lipo -create $INPUT_LIBS \
	-output "${OUTPUTDIR}/lib/${OUTPUT_LIB}"
else
	echo "$OUTPUT_LIB does not exist, skipping (are the dependencies installed?)"
fi



####################

# Create xcarchive for the device

# Device xcarchive (arm64)
cd "${REPOROOT}/opus"
xcodebuild archive \
  -scheme "${SCHEME}" \
  -project "${SCHEME}.xcodeproj" \
  -archivePath ${DEVICE_ARCHIVE_PATH} \
  -sdk iphoneos \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

# Remove the intermediate files from the device build
rm -fr ${INTERDIR}
# Remove the simulator static library
rm "${OUTPUTDIR}/lib/${OUTPUT_LIB}"


####################

FRAMEWORK_NAME="OpusKit.xcframework"
FRAMEWORK_PATH="${OUTPUTDIR}/${FRAMEWORK_NAME}"

# Clean-up any existing instance of this xcframework from the Products directory
if [ -e ${FRAMEWORK_PATH} ]; then
	echo "Removing existing xcframework"
	rm -rf ${FRAMEWORK_PATH}
fi

# Create final xcframework
xcodebuild -create-xcframework \
  -framework ${DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${SCHEME}.framework \
  -framework ${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${SCHEME}.framework \
  -output ${FRAMEWORK_PATH}

echo "Building done."

echo "Compressing xcframework"
cd ${OUTPUTDIR}

echo "current directory for create zipfile " $(pwd)


zip -r "${FRAMEWORK_NAME}.zip" "${FRAMEWORK_NAME}"
mv "${FRAMEWORK_NAME}.zip" "${REPOROOT}/."


echo "Cleaning up..."
rm -fr "${SRCDIR}/opus-${VERSION}"

echo "Done."
