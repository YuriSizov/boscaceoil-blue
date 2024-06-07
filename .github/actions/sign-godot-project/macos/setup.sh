#!/bin/bash

# Based on https://github.com/godot-jolt/godot-jolt/blob/master/scripts/ci_sign_macos.ps1

certificate_base64="$APPLE_CERT_BASE64"
certificate_password="$APPLE_CERT_PASSWORD"

if [ -z "${certificate_base64}" ]; then
  echo "ERROR: Missing codesign certificate."
  exit 1
fi
if [ -z "${certificate_password}" ]; then
  echo "ERROR: Missing codesign certificate password."
  exit 1
fi

# Convert the certificate back to its file form.

echo "Decoding the base64 certificate..."

certificate_path="certificate.p12"
base64 --decode -o ${certificate_path} <<< "${certificate_base64}"

# Set up the keychain and import the certificate.

keychain="ephemeral.keychain"
keychain_password="$(openssl rand -base64 16)"

echo "Creating the default keychain..."

security create-keychain -p ${keychain_password} ${keychain}
security default-keychain -s ${keychain}

echo "Importing the certificate into the keychain..."

security import ${certificate_path} -k ~/Library/Keychains/${keychain} -P ${certificate_password} -T /usr/bin/codesign
security find-identity

echo "Granting access to the keychain..."

security set-key-partition-list -S "apple-tool:,apple:" -s -k ${keychain_password} ${keychain}
security set-keychain-settings ${keychain}
