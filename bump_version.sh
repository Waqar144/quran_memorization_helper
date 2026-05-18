#!/bin/bash

set -e

# Check if a version argument was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <new-version>"
    echo "Example: $0 1.7.6"
    exit 1
fi

NEW_VER=$1
BASE=$(git rev-parse --show-toplevel)
PUBSPEC_FILE="$BASE/pubspec.yaml"
VERSION_FILE="$BASE/lib/pages/settings_page.dart"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "Error: $PUBSPEC_FILE not found!"
    exit 1
fi

OLD_VERSION=$(grep '^version:' "$PUBSPEC_FILE" | sed 's/^version: //')

# 1. Extract the current build number (the part after the +)
# We search for the line starting with 'version:'
CURRENT_BUILD=$(grep '^version:' "$PUBSPEC_FILE" | cut -d '+' -f 2)

# 2. Increment the build number
# If no build number exists, it defaults to 1
NEXT_BUILD=$((CURRENT_BUILD + 1))

# 3. Use sed to replace the entire version line
# This looks for '^version: ...' and replaces it with 'version: NEW_VER+NEXT_BUILD'
sed -i "s/^version: .*/version: ${NEW_VER}+${NEXT_BUILD}/" "$PUBSPEC_FILE"

echo "Updated $PUBSPEC_FILE to version: ${NEW_VER}+${NEXT_BUILD}, old version: ${OLD_VERSION}"


# 4. Update version in settings page
sed -i "s/const String appVersion = \".*\";/const String appVersion = \"${NEW_VER}\";/" "$VERSION_FILE"

echo "Updated $VERSION_FILE to version: ${NEW_VER}+${NEXT_BUILD}, old version: ${OLD_VERSION}"

git add $VERSION_FILE $PUBSPEC_FILE
git commit -m "Bump version to ${NEW_VER}"
git tag ${NEW_VER}
git log -n 1
