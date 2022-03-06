#!/bin/bash

#
# CommandPost Build Release Script
#

#
# Store some variables for later:
#

export SCRIPT_HOME ; SCRIPT_HOME="$(dirname "$(greadlink -f "$0")")"
export COMMANDPOST_HOME ; COMMANDPOST_HOME="$(greadlink -f "${SCRIPT_HOME}/../")"

#
# Get the CommandPost version from the current GitHub Tag:
#

export VERSION ; VERSION=$(cd "${COMMANDPOST_HOME}/../CommandPost-App/" || fail "Unable to enter ${COMMANDPOST_HOME}/../CommandPost-App/" ; git describe --abbrev=0)

#
# These variables are used within the CommandPost-App Build Script:
#

export SENTRY_ORG=commandpost
export SENTRY_PROJECT=commandpost

#
# Setup Token Paths:
#

export TOKENPATH; TOKENPATH="${COMMANDPOST_HOME}/.."
export NOTARIZATION_TOKEN_FILE="${TOKENPATH}/token-notarization"

#
# Make sure we have the Notorization Token File:
#

function assert_notarization_token() {
  echo "Checking for notarization token..."
  if [ ! -f "${NOTARIZATION_TOKEN_FILE}" ]; then
    fail "You do not have a notarization token in ${NOTARIZATION_TOKEN_FILE}"
  fi
}

assert_notarization_token && source "${NOTARIZATION_TOKEN_FILE}"

#
# Build Uninstall Script:
#

function build_uninstall() {
	echo "Building Uninstall Script..."
	rm -rf ../CommandPost/scripts/inc/uninstall/Uninstall\ CommandPost.app
	osacompile -x -o ../CommandPost/scripts/inc/uninstall/Uninstall\ CommandPost.app ../CommandPost/scripts/inc/uninstall/Uninstall\ CommandPost.scpt
	cp ../CommandPost/scripts/inc/uninstall/applet.icns ../CommandPost/scripts/inc/uninstall/Uninstall\ CommandPost.app/Contents/Resources/applet.icns
	xattr -cr ../CommandPost/scripts/inc/uninstall/Uninstall\ CommandPost.app
	codesign --verbose --force --deep --options=runtime --timestamp --entitlements ../CommandPost/scripts/inc/uninstall/Uninstall\ CommandPost.entitlements --sign "Developer ID Application: LateNite Films Pty Ltd" ../CommandPost/scripts/inc/uninstall/Uninstall\ CommandPost.app
	codesign -dv --verbose=4 ../CommandPost/scripts/inc/uninstall/Uninstall\ CommandPost.app
}

#
# Build DMG using DMG Canvas:
#

function build_dmgcanvas() {
	echo "Remove Old DMG..."
	rm -f "../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg"

	echo "Building DMG..."
	mkdir -p "../CommandPost-Releases/${VERSION}"
	/Applications/DMG\ Canvas.app/Contents/Resources/dmgcanvas "../CommandPost/scripts/inc/dmgcanvas/CommandPost.dmgCanvas" "../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg" -setFilePath CommandPost.app "../CommandPost-App/build/CommandPost.app" -setFilePath "Uninstall CommandPost.app" "../CommandPost/scripts/inc/uninstall/Uninstall CommandPost.app" -setFilePath "Applications" "/Applications/"

	if [ ! -f "../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg" ]; then
	fail "DMG Creation Failed"
	else
	echo "DMG Creation Successful"
	fi
}

#
# Notarize:
#

function assert_notarization_acceptance() {
    echo "Ensuring Notarization acceptance..."
    if ! xcrun stapler validate "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg" ; then
        fail "Notarization rejection"
        exit 1
    fi
}

function upload_to_notary_service() {
    echo "Uploading to Apple Notarization Service..."
    pushd "${COMMANDPOST_HOME}" >/dev/null
    mkdir -p "../archive/${VERSION}"
    local OUTPUT=""
    OUTPUT=$(xcrun altool --notarize-app \
                --primary-bundle-id "org.latenitefilms.CommandPost" \
                --file "../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg" \
                --username "${NOTARIZATION_USERNAME}" \
                --password "${NOTARIZATION_PASSWORD}" \
                2>&1 | tee "../archive/${VERSION}/notarization-upload.log" \
    )
    if [ "$?" != "0" ]; then
        echo "$OUTPUT"
        fail "Notarization upload failed."
    fi
    NOTARIZATION_REQUEST_UUID=$(echo ${OUTPUT} | sed -e 's/.*RequestUUID = //')
    echo "Notarization request UUID: ${NOTARIZATION_REQUEST_UUID}"
    popd >/dev/null
}

function wait_for_notarization() {
    echo -n "Waiting for Notarization..."
    while true ; do
        local OUTPUT=""
        OUTPUT=$(check_notarization_status)
        if [ "${OUTPUT}" == "Success" ] ; then
            echo ""
            break
        elif [ "${OUTPUT}" == "Working" ]; then
            echo -n "."
		elif [ "${OUTPUT}" == "No URL yet" ]; then
            echo -n "_"
        else
            echo ""
            fail "Unknown output: ${OUTPUT}"
        fi
        sleep 60
    done
    echo ""
}

function check_notarization_status() {
    local OUTPUT=""
    OUTPUT=$(xcrun altool --notarization-info "${NOTARIZATION_REQUEST_UUID}" \
                --username "${NOTARIZATION_USERNAME}" \
                --password "${NOTARIZATION_PASSWORD}" \
                2>&1 \
    )
    local RESULT=""
    RESULT=$(echo "${OUTPUT}" | grep "Status: " | sed -e 's/.*Status: //')
    if [ "${RESULT}" == "in progress" ]; then
        echo "Working"
        return
    fi

    local NOTARIZATION_LOG_URL=""
    NOTARIZATION_LOG_URL=$(echo "${OUTPUT}" | grep "LogFileURL: " | awk '{ print $2 }')
	if [ "${NOTARIZATION_LOG_URL}" == "" ]; then
        echo "No URL yet"
        return
    fi
    echo "Fetching Notarization log: ${NOTARIZATION_LOG_URL}" >/dev/stderr
    local STATUS=""
    STATUS=$(curl "${NOTARIZATION_LOG_URL}")
    RESULT=$(echo "${STATUS}" | jq -r .status)

    case "${RESULT}" in
        "Accepted")
            echo "Success"
            ;;
        "in progress")
            echo "Working"
            ;;
        *)
            echo "${STATUS}" | tee "../archive/${VERSION}/notarization.log"
            echo "Notarization failed: ${RESULT}"
            ;;
    esac
}

function staple_notarization() {
    echo "Stapling notarization to app bundle..."
    pushd "${COMMANDPOST_HOME}/../CommandPost-App/build" >/dev/null
    xcrun stapler staple "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg"
    popd >/dev/null
}


function notarize() {
  echo "******** NOTARIZING:"
  upload_to_notary_service
  wait_for_notarization
  staple_notarization
  assert_notarization_acceptance
}

#
# Generate Appcast:
#

function generate_appcast() {

  echo "Remove Old AppCast..."
  rm -f "../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.txt"

  echo "Generating AppCast Content..."
  export SPARKLE_DSA_SIGNATURE

  SPARKLE_DSA_SIGNATURE="$(../CommandPost/scripts/inc/sign_update "../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg" "../dsa_priv.pem")"

  local BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Hammerspoon/CommandPost-Info.plist)

  touch "../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.txt"
  echo "
		<item>
			<title>Version ${VERSION}</title>
			<sparkle:releaseNotesLink>https://commandpost.github.io/CommandPost/releasenotes.html</sparkle:releaseNotesLink>
			<pubDate>$(date +"%a, %e %b %Y %H:%M:%S %z")</pubDate>
			<enclosure url=\"https://github.com/CommandPost/CommandPost/releases/download/${VERSION}/CommandPost_${VERSION}.dmg\"
				sparkle:version=\"${BUILD_NUMBER}\"
                sparkle:shortVersionString=\"${VERSION}\"
				sparkle:dsaSignature=\"${SPARKLE_DSA_SIGNATURE}\"
				type=\"application/octet-stream\"
			/>
			<sparkle:minimumSystemVersion>10.12</sparkle:minimumSystemVersion>
		</item>" >> "../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.txt"
}

#
# Build CommandPost-App:
#

echo "Quitting any active CommandPost instances..."
killall CommandPost

echo "Going to the CommandPost-App Folder..."
cd ../
cd CommandPost-App/

echo "Trashing the build folder..."

rm -rf build
mkdir build

set -eu
set -o pipefail

echo "Clean up..."
./scripts/build.sh clean

echo "Lets build!"
./scripts/build.sh build -s Release -c Release -d -u

echo "Build docs..."
./scripts/build.sh docs

build_uninstall
build_dmgcanvas
notarize
generate_appcast