#!/bin/bash

# Based on https://github.com/godot-jolt/godot-jolt/blob/master/scripts/ci_sign_macos.ps1

apple_dev_id="$APPLE_DEV_ID"
apple_dev_app_id="$APPLE_DEV_APP_ID"
apple_dev_team_id="$APPLE_DEV_TEAM_ID"
apple_dev_password="$APPLE_DEV_PASSWORD"

app_path="$APP_PATH"
archive_path="$APP_PATH.zip"

if [ -z "${apple_dev_id}" ]; then
  echo "ERROR: Missing Apple developer ID."
  exit 1
fi
if [ -z "${apple_dev_app_id}" ]; then
  echo "ERROR: Missing Apple developer application ID."
  exit 1
fi
if [ -z "${apple_dev_team_id}" ]; then
  echo "ERROR: Missing Apple team ID."
  exit 1
fi
if [ -z "${apple_dev_password}" ]; then
  echo "ERROR: Missing Apple developer password."
  exit 1
fi
if [ -z "${app_path}" ]; then
  echo "ERROR: Missing application path to sign."
  exit 1
fi

# Sign, notarize, and staple the app.

echo "Signing and verifying the app at '${app_path}'..."

codesign --timestamp --verbose --deep --force --options runtime --sign "${apple_dev_app_id}" "${app_path}"
codesign --verify "${app_path}"

echo "Archiving and notarizing the signed app..."

ditto -ck --keepParent "${app_path}" "${archive_path}"
xcrun notarytool submit "${archive_path}" --apple-id ${apple_dev_id} --team-id ${apple_dev_team_id} --password ${apple_dev_password} --wait || { exit 1; }

echo "Stapling the notarization ticket to the signed app..."

xcrun stapler staple "${app_path}"

echo "Cleaning up..."

rm -f "${archive_path}"
