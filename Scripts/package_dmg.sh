#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCRIPT_NAME="$(basename "$0")"

PROJECT_PATH="${PROJECT_PATH:-${ROOT_DIR}/SpeakIt.xcodeproj}"
SCHEME="${SCHEME:-SpeakIt}"
CONFIGURATION="${CONFIGURATION:-Release}"
APP_NAME="${APP_NAME:-SpeakIt}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${ROOT_DIR}/.build/DerivedData}"
BUILD_DIR="${BUILD_DIR:-${ROOT_DIR}/dist}"
ARCHIVE_DIR="${ARCHIVE_DIR:-${BUILD_DIR}/archive}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${ARCHIVE_DIR}/${APP_NAME}.xcarchive}"
DMG_NAME="${DMG_NAME:-${APP_NAME}.dmg}"
VOLUME_NAME="${VOLUME_NAME:-${APP_NAME}}"
MODE="${MODE:-archive}"
CLEAN="${CLEAN:-0}"
WINDOW_BOUNDS="${WINDOW_BOUNDS:-120,120,660,420}"
APP_ICON_POS="${APP_ICON_POS:-160,190}"
APPLICATIONS_ICON_POS="${APPLICATIONS_ICON_POS:-500,190}"
RW_DMG_SIZE="${RW_DMG_SIZE:-200m}"

TEMP_DIR=""
MOUNT_DEVICE=""
MOUNT_PATH=""

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Build the macOS app and package it into a drag-install DMG.
Default mode uses xcodebuild archive and packages the archived .app.

Options:
  --project PATH        Xcode project path. Default: ${PROJECT_PATH}
  --scheme NAME         Xcode scheme. Default: ${SCHEME}
  --configuration NAME  Build configuration. Default: ${CONFIGURATION}
  --app-name NAME       App bundle name without .app. Default: ${APP_NAME}
  --mode NAME           build or archive. Default: ${MODE}
  --build-dir PATH      Output directory for the app and dmg. Default: ${BUILD_DIR}
  --derived-data PATH   DerivedData path. Default: ${DERIVED_DATA_PATH}
  --archive-path PATH   Archive output path. Default: ${ARCHIVE_PATH}
  --clean               Remove previous build, archive, app, and dmg outputs first.
  --dmg-name NAME       DMG filename. Default: ${DMG_NAME}
  --volume-name NAME    Mounted DMG volume name. Default: ${VOLUME_NAME}
  -h, --help            Show this help.

Examples:
  ${SCRIPT_NAME} --clean
  ${SCRIPT_NAME} --mode build
  ${SCRIPT_NAME} --configuration Debug --build-dir "${ROOT_DIR}/out"
EOF
}

cleanup() {
    set +e
    if [[ -n "${MOUNT_DEVICE}" ]]; then
        hdiutil detach "${MOUNT_DEVICE}" -quiet >/dev/null 2>&1 || true
    fi
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --scheme)
            SCHEME="$2"
            shift 2
            ;;
        --configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        --app-name)
            APP_NAME="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --derived-data)
            DERIVED_DATA_PATH="$2"
            shift 2
            ;;
        --archive-path)
            ARCHIVE_PATH="$2"
            shift 2
            ;;
        --clean)
            CLEAN=1
            shift
            ;;
        --dmg-name)
            DMG_NAME="$2"
            shift 2
            ;;
        --volume-name)
            VOLUME_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ "${MODE}" != "build" && "${MODE}" != "archive" ]]; then
    echo "Invalid mode: ${MODE}. Expected 'build' or 'archive'." >&2
    exit 1
fi

mkdir -p "${BUILD_DIR}" "${DERIVED_DATA_PATH}" "$(dirname "${ARCHIVE_PATH}")"

APP_BUNDLE_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
ARCHIVED_APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"
STAGED_APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
RW_DMG_PATH="${BUILD_DIR}/${APP_NAME}-temp.dmg"

if [[ "${CLEAN}" == "1" ]]; then
    echo "Cleaning previous outputs..."
    rm -rf "${STAGED_APP_PATH}" "${DMG_PATH}" "${RW_DMG_PATH}" "${ARCHIVE_PATH}" "${DERIVED_DATA_PATH}"
    mkdir -p "${BUILD_DIR}" "${DERIVED_DATA_PATH}" "$(dirname "${ARCHIVE_PATH}")"
fi

if [[ "${MODE}" == "archive" ]]; then
    echo "Archiving ${APP_NAME}.app..."
    xcodebuild \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        -destination "platform=macOS" \
        -archivePath "${ARCHIVE_PATH}" \
        archive

    if [[ ! -d "${ARCHIVED_APP_PATH}" ]]; then
        echo "Archive succeeded but app not found at: ${ARCHIVED_APP_PATH}" >&2
        exit 1
    fi

    SOURCE_APP_PATH="${ARCHIVED_APP_PATH}"
else
    echo "Building ${APP_NAME}.app..."
    xcodebuild \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        -destination "platform=macOS" \
        build

    if [[ ! -d "${APP_BUNDLE_PATH}" ]]; then
        echo "Build succeeded but app not found at: ${APP_BUNDLE_PATH}" >&2
        exit 1
    fi

    SOURCE_APP_PATH="${APP_BUNDLE_PATH}"
fi

echo "Preparing output..."
rm -rf "${STAGED_APP_PATH}" "${DMG_PATH}" "${RW_DMG_PATH}"
cp -R "${SOURCE_APP_PATH}" "${STAGED_APP_PATH}"

TEMP_DIR="$(mktemp -d "${BUILD_DIR}/dmg.XXXXXX")"
cp -R "${STAGED_APP_PATH}" "${TEMP_DIR}/"
ln -s /Applications "${TEMP_DIR}/Applications"

echo "Creating temporary DMG..."
hdiutil create \
    -srcfolder "${TEMP_DIR}" \
    -volname "${VOLUME_NAME}" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size "${RW_DMG_SIZE}" \
    -ov \
    "${RW_DMG_PATH}" >/dev/null

echo "Mounting temporary DMG..."
ATTACH_OUTPUT="$(hdiutil attach "${RW_DMG_PATH}" -readwrite -noverify -noautoopen)"
MOUNT_DEVICE="$(echo "${ATTACH_OUTPUT}" | awk '/Apple_HFS/ {print $1; exit}')"
MOUNT_PATH="$(echo "${ATTACH_OUTPUT}" | awk -F'\t' '/Apple_HFS/ {print $3; exit}')"

if [[ -z "${MOUNT_DEVICE}" || -z "${MOUNT_PATH}" ]]; then
    echo "Failed to mount temporary DMG." >&2
    exit 1
fi

echo "Configuring drag-install layout..."
osascript >/dev/null <<EOF || echo "Finder layout customization skipped; DMG will still support drag-install."
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {${WINDOW_BOUNDS}}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set text size of viewOptions to 14
        set position of item "${APP_NAME}.app" of container window to {${APP_ICON_POS}}
        set position of item "Applications" of container window to {${APPLICATIONS_ICON_POS}}
        update without registering applications
        delay 1
        close
        open
        delay 1
    end tell
end tell
EOF

sync
sync

echo "Finalizing DMG..."
hdiutil detach "${MOUNT_DEVICE}" -quiet
MOUNT_DEVICE=""
MOUNT_PATH=""

hdiutil convert "${RW_DMG_PATH}" -format UDZO -imagekey zlib-level=9 -ov -o "${DMG_PATH}" >/dev/null
rm -f "${RW_DMG_PATH}"

echo "Done."
echo "App: ${STAGED_APP_PATH}"
if [[ "${MODE}" == "archive" ]]; then
    echo "Archive: ${ARCHIVE_PATH}"
fi
echo "DMG: ${DMG_PATH}"
