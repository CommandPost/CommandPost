#!/bin/bash

#
# COMMANDPOST BUILD RELEASE SCRIPT:
#

set -eu
set -o pipefail

#
# Define Variables:
#

export SENTRY_ORG=commandpost
export SENTRY_PROJECT=commandpost
export SENTRY_LOG_LEVEL=debug

export SCRIPT_HOME ; SCRIPT_HOME="$(dirname "$(greadlink -f "$0")")"
export COMMANDPOST_HOME ; COMMANDPOST_HOME="$(greadlink -f "${SCRIPT_HOME}/../")"
export VERSION ; VERSION=$(cd "${COMMANDPOST_HOME}/../CommandPost-App/" || fail "Unable to enter ${COMMANDPOST_HOME}/../CommandPost-App/" ; git describe --abbrev=0)

#
# Build Uninstall Script:
#

function build_uninstall() {
	rm -rf "${COMMANDPOST_HOME}/scripts/inc/uninstall/Uninstall CommandPost.app"
	osacompile -x -o "${COMMANDPOST_HOME}/scripts/inc/uninstall/Uninstall CommandPost.app" "${COMMANDPOST_HOME}/scripts/inc/uninstall/Uninstall CommandPost.scpt"
	cp "${COMMANDPOST_HOME}/scripts/inc/uninstall/applet.icns" "${COMMANDPOST_HOME}/scripts/inc/uninstall/Uninstall CommandPost.app/Contents/Resources/applet.icns"
	xattr -cr "${COMMANDPOST_HOME}/scripts/inc/uninstall/Uninstall CommandPost.app"
	codesign --verbose --force --deep --options=runtime --timestamp --entitlements "${COMMANDPOST_HOME}/scripts/inc/uninstall/Uninstall CommandPost.entitlements" --sign "Developer ID Application: LateNite Films Pty Ltd" "${COMMANDPOST_HOME}/scripts/inc/uninstall/Uninstall CommandPost.app"
	codesign -dv --verbose=4 "${COMMANDPOST_HOME}/../CommandPost/scripts/inc/uninstall/Uninstall CommandPost.app"
}

#
# Build DMG using DMG Canvas:
#

function build_dmgcanvas() {
	echo "  * Removing Old DMG..."
	rm -f "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg"

	echo "  * Building New DMG..."
	mkdir -p "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}"
	/Applications/DMG\ Canvas.app/Contents/Resources/dmgcanvas "${COMMANDPOST_HOME}/../CommandPost/scripts/inc/dmgcanvas/CommandPost.dmgCanvas" "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg" -setFilePath CommandPost.app "${COMMANDPOST_HOME}/../CommandPost-App/build/CommandPost.app" -setFilePath "Uninstall CommandPost.app" "${COMMANDPOST_HOME}/../CommandPost/scripts/inc/uninstall/Uninstall CommandPost.app" -setFilePath "Applications" "/Applications/"

	if [ ! -f "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg" ]; then
	fail "  * DMG Creation Failed!"
	else
	echo "  * DMG Creation Successful!"
	fi
}

#
# Generate Appcast:
#

function generate_appcast() {

  echo "  * Remove Old AppCast..."
  rm -f "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.txt"

  echo "  * Generating New AppCast..."

  #
  # Generate DSA Signature (legacy for Sparkle 1.0):
  #

  export SPARKLE_DSA_SIGNATURE
  SPARKLE_DSA_SIGNATURE="$(${COMMANDPOST_HOME}/../CommandPost/scripts/inc/sparkle1/sign_update "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg" "${COMMANDPOST_HOME}/../dsa_priv.pem")"

  #
  # Generate EdDSA Signature (for Sparkle 2.0):
  #

  export SPARKLE_ED_SIGNATURE
  SPARKLE_ED_SIGNATURE="$(${COMMANDPOST_HOME}/../CommandPost/scripts/inc/sparkle2/sign_update "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg")"

  #
  # Get Build Number from plist:
  #

  local BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Hammerspoon/CommandPost-Info.plist)

  touch "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.txt"
  echo "
		<item>
			<title>Version ${VERSION}</title>
			<sparkle:releaseNotesLink>https://commandpost.github.io/CommandPost/releasenotes.html</sparkle:releaseNotesLink>
			<pubDate>$(date +"%a, %e %b %Y %H:%M:%S %z")</pubDate>
			<enclosure url=\"https://github.com/CommandPost/CommandPost/releases/download/${VERSION}/CommandPost_${VERSION}.dmg\"
				sparkle:version=\"${BUILD_NUMBER}\"
                sparkle:shortVersionString=\"${VERSION}\"
				sparkle:dsaSignature=\"${SPARKLE_DSA_SIGNATURE}\"
				${SPARKLE_ED_SIGNATURE}
				type=\"application/octet-stream\"
			/>
			<sparkle:minimumSystemVersion>10.15</sparkle:minimumSystemVersion>
		</item>" >> "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.txt"
}

#
# Finalise Sentry:
#

function finalise_sentry() {

    echo "  * Updating Sentry release..."

    export TOKENPATH ; TOKENPATH="$(greadlink -f "${COMMANDPOST_HOME}/..")"
    export SENTRY_TOKEN_AUTH_FILE="${TOKENPATH}/token-sentry-auth"

	echo "  * Importing Sentry token from: ${TOKENPATH}/token-sentry-auth"
	# shellcheck disable=SC1090
	source "${SENTRY_TOKEN_AUTH_FILE}"

    export SENTRY_AUTH_TOKEN
    "${COMMANDPOST_HOME}/../CommandPost-App/scripts/sentry-cli" releases set-commits --auto "${VERSION}" 2>&1 | tee "${COMMANDPOST_HOME}/../CommandPost-App/build/sentry-release.log"
    "${COMMANDPOST_HOME}/../CommandPost-App/scripts/sentry-cli" releases finalize "${VERSION}" 2>&1 | tee -a "${COMMANDPOST_HOME}/../CommandPost-App/build/sentry-release.log"

}

#
# Build CommandPost-App:
#

echo " * Quitting any active CommandPost instances..."
killall CommandPost || true

echo " * Moving to CommandPost-App Directory..."
cd "${COMMANDPOST_HOME}/../CommandPost-App/"

echo " * Cleaning up prior to build..."
./scripts/build.sh clean

echo " * Building CommandPost-App..."
./scripts/build.sh build -s Release -c Release -d -u

echo " * Building CommandPost-App Docs..."
./scripts/build.sh docs

echo " * Building Uninstall App..."
build_uninstall

echo " * Building DMG for distribution..."
build_dmgcanvas

echo " * Notorizing DMG..."
./scripts/build.sh notarize -z "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg"

echo " * Generating new AppCast..."
generate_appcast

echo " * Finalise Sentry..."
finalise_sentry

echo " * CommandPost has been successfully built!"