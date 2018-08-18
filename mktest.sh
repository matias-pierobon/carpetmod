#!/bin/sh

# Parse command line args
TEST=0
while [ $# -gt 0 ]; do

    key="$1"

    case $key in
        -d|--download)
            URL="$2"
            shift
            shift
            ;;
        -o|--outfile)
            OUTFILE="$2"
            shift
            shift
            ;;
        -t|--test)
            TEST=1
            shift
            ;;
        -h|--help)
            # immediately print help
            echo "$0 [-d,--download URL] [-o,--outfile OUTFILE]"
            echo " install and test Carpet patches"
            echo ""
            echo "options:"
            echo " -d,--download URL    download patches from given URL"
            echo " -o,--outfile OUTFILE output to given file"
            echo " -t,--test            run a test"
            exit 0
            shift
            shift
            ;;
    esac
done

carpet_name="carpet-1.12-`date +%F`.jar"
echo "Cleaning previous installations ..."
rm -rf "build/tmp/fullRelease/*"
mkdir -p "build/tmp/fullRelease"

if [ "x$URL" != "x" ]; then
    echo "Downloading patches..."
    mkdir -p download
    PATCH_PATH="`pwd`/download/carpet_patches.zip"
    wget "$URL" -O "$PATCH_PATH" || { echo "download failed!" && exit 1; }
else
    PATCH_PATH="`pwd`/build/distributions/Carpetmod_dev.zip"
fi

echo "Copying server ..."
BUILD_DIR="`pwd`/build/tmp/fullRelease"
MC_JAR="$BUILD_DIR/minecraft_server.1.12.jar"
if [ -f "$MC_JAR.orig" ]; then
    cp "$MC_JAR.orig" "$MC_JAR"
else
    GRADLE_CACHE_JAR="$HOME/.gradle/caches/minecraft/net/minecraft/minecraft_server/1.12/minecraft_server-1.12.jar"
    if [ -f "$GRADLE_CACHE_JAR" ]; then
        cp "$GRADLE_CACHE_JAR" "$MC_JAR"
    else
        echo "Downloading server ..."
        wget "https://s3.amazonaws.com/Minecraft.Download/versions/1.12/minecraft_server.1.12.jar" -O "$MC_JAR" || { echo "failed to download MC jar" && exit 1; }
        cp "$MC_JAR" "$MC_JAR.orig"
    fi
fi

if false; then
    echo "Extracting patches ..."
    mkdir -p "$BUILD_DIR/patches"
    unzip "$PATCH_PATH" -d "$BUILD_DIR/patches" || { echo "failed to extract patches!" && exit 1; }
fi

echo "Patch work ..."
zip -q "$PATCH_PATH" "*" -u -o "$MC_JAR"

echo "Cleanup ..."
pushd "$BUILD_DIR"
rm -rf "patches"
mv "$MC_JAR" "../../$carpet_name"
popd

if [ "x$OUTFILE" != "x" ]; then
    cp "build/$carpet_name" "$OUTFILE"
fi

if [ "$TEST" = "1" ]; then
    echo "Starting server ..."
    rm -rf "test"
    mkdir -p "test"
    read -p "Do you agree to the Minecraft EULA? [y/n]" eula
    if [ "$eula" = "y" ]; then
        echo "eula=true" > "test/eula.txt"
    else
        echo "You'll have to edit 'test/eula.txt' to run the server."
    fi
    cp "build/$carpet_name" "test/$carpet_name"
    pushd "test"
    java -jar "$carpet_name" --nogui
    popd
fi
