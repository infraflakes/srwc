#!/bin/sh
# Build a release tarball for srwm.
# Usage: ./release.sh
# Produces: srwm-<version>-x86_64-linux.tar.gz

set -e

VERSION=$(grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)"/\1/')
ARCHIVE="srwm-${VERSION}-x86_64-linux.tar.gz"
STAGING="srwm-${VERSION}"

cargo build --release

rm -rf "$STAGING"
mkdir -p "$STAGING/wallpapers"

cp target/release/srwm "$STAGING/"
cp resources/srwm-session "$STAGING/"
cp resources/srwm.desktop "$STAGING/"
cp resources/srwm-portals.conf "$STAGING/"
cp config.example.toml "$STAGING/config.toml"
cp extras/wallpapers/*.glsl "$STAGING/wallpapers/"

tar czf "$ARCHIVE" "$STAGING"
rm -rf "$STAGING"

echo "Built $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
