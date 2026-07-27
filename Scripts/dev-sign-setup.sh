#!/usr/bin/env bash
# Create a stable, self-signed code-signing identity for LOCAL development.
#
# Why: ad-hoc signing (the default) changes the app's signature on every build,
# so macOS drops the Accessibility grant each time. A stable identity ties the
# grant to the certificate instead, so you grant once and rebuilds keep it.
#
# Run ONCE:   ./Scripts/dev-sign-setup.sh   (asks for your login password once)
# Then use:   ./Scripts/dev-run.sh          (builds signed + installs + launches)
#
# This identity is for LOCAL use only. Releases stay ad-hoc (see build.sh).
set -euo pipefail

CERT_NAME="KeyboardCleaner Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning 2>/dev/null | grep -q "$CERT_NAME"; then
  echo "✅ Signing identity '$CERT_NAME' already exists — nothing to do."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Generating self-signed code-signing certificate"
openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -subj "/CN=$CERT_NAME" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning"

openssl pkcs12 -export \
  -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -name "$CERT_NAME" -out "$TMP/identity.p12" -passout pass:kbc

echo "==> Importing into your login keychain"
security import "$TMP/identity.p12" -k "$KEYCHAIN" -P kbc \
  -T /usr/bin/codesign -T /usr/bin/security

echo "==> Authorizing codesign to use the key (macOS will ask for your login password)"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s "$KEYCHAIN" >/dev/null

echo
echo "✅ Created '$CERT_NAME'."
echo "   Next:  ./Scripts/dev-run.sh   then grant Accessibility ONE more time."
echo "   After that, rebuilds keep the grant."
