#!/bin/bash
set -euo pipefail

###############################################################################
#                         DEGERIS INSTALLER
#                    GitHub Release Bootstrap
###############################################################################

REPO_OWNER="Degeris"
REPO_NAME="Degeris"
ASSET_NAME="setup.zip"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

say() {
    echo -e "${CYAN}$1${NC}"
}

ok() {
    echo -e "${GREEN}✓ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

clear 2>/dev/null || true

echo "=============================================="
echo "              DEGERIS INSTALLER"
echo "=============================================="
echo
echo "سلام کاربر گرامی 👋"
echo
echo "بنده Degerist هستم، سازنده پنل Degeris."
echo
echo "Telegram Channel : https://t.me/DegerisVPN"
echo "Telegram Admin   : https://t.me/Degeris"
echo "GitHub           : https://github.com/Degeris"
echo
echo "=============================================="
echo

###############################################################################
# ROOT CHECK
###############################################################################

if [[ "$EUID" -ne 0 ]]; then
    fail "Please run this installer as root."
fi

###############################################################################
# ARGUMENT
###############################################################################

REQUESTED_VERSION="${1:-}"

###############################################################################
# INSTALL DEPENDENCIES
###############################################################################

say "[1/6] Checking required packages..."

export DEBIAN_FRONTEND=noninteractive

if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y curl unzip

    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl unzip

    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl unzip

    else
        fail "Could not detect a supported package manager."
    fi

fi

ok "Required packages are available."

###############################################################################
# TEMP DIRECTORY
###############################################################################

TMP_DIR="$(mktemp -d -t degeris-installer-XXXXXXXX)"

ZIP_FILE="$TMP_DIR/$ASSET_NAME"
APP_DIR="$TMP_DIR/app"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

mkdir -p "$APP_DIR"

###############################################################################
# GET RELEASE VERSION
###############################################################################

say "[2/6] Selecting Degeris version..."

API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases"

if [[ -n "$REQUESTED_VERSION" ]]; then

    VERSION="$REQUESTED_VERSION"

    say "Requested version: $VERSION"

    RELEASE_URL="${API_URL}/tags/${VERSION}"

    RELEASE_JSON="$(curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        "$RELEASE_URL" \
        2>/dev/null) \
        || fail "Release version '$VERSION' was not found."

else

    say "No version specified."
    say "Finding latest Degeris release..."

    RELEASE_JSON="$(curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        "$API_URL/latest" \
        2>/dev/null) \
        || fail "Could not retrieve the latest Degeris release."

    VERSION="$(printf '%s' "$RELEASE_JSON" \
        | grep -m1 '"tag_name"' \
        | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/')"

    if [[ -z "$VERSION" ]]; then
        fail "Could not determine latest release version."
    fi

fi

echo
ok "Selected version: $VERSION"

###############################################################################
# FIND SETUP.ZIP
###############################################################################

say "[3/6] Locating release asset..."

DOWNLOAD_URL="$(printf '%s' "$RELEASE_JSON" \
    | grep -oE '"browser_download_url":[[:space:]]*"[^"]+"' \
    | sed -E 's/"browser_download_url":[[:space:]]*"([^"]+)"/\1/' \
    | grep "/${ASSET_NAME}$" \
    | head -n1 || true)"

if [[ -z "$DOWNLOAD_URL" ]]; then

    # Fallback to standard GitHub release URL
    DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${ASSET_NAME}"

fi

echo
echo "Release : $VERSION"
echo "Asset   : $ASSET_NAME"
echo
echo "Download:"
echo "$DOWNLOAD_URL"
echo

###############################################################################
# DOWNLOAD
###############################################################################

say "[4/6] Downloading Degeris $VERSION..."

curl -fL \
    --retry 3 \
    --retry-delay 2 \
    --connect-timeout 15 \
    --max-time 0 \
    "$DOWNLOAD_URL" \
    -o "$ZIP_FILE" \
    || fail "Failed to download Degeris $VERSION."

if [[ ! -s "$ZIP_FILE" ]]; then
    fail "Downloaded setup.zip is empty."
fi

ok "Download completed."

###############################################################################
# VALIDATE ZIP
###############################################################################

say "[5/6] Checking setup.zip..."

if ! unzip -t "$ZIP_FILE" >/dev/null 2>&1; then
    fail "setup.zip is corrupted or invalid."
fi

ok "setup.zip is valid."

###############################################################################
# EXTRACT
###############################################################################

say "Extracting setup.zip..."

unzip -q "$ZIP_FILE" -d "$APP_DIR"

###############################################################################
# FIND ORIGINAL INSTALLER
###############################################################################

ORIGINAL_INSTALLER=""

if [[ -f "$APP_DIR/install.sh" ]]; then

    ORIGINAL_INSTALLER="$APP_DIR/install.sh"

else

    ORIGINAL_INSTALLER="$(find "$APP_DIR" \
        -type f \
        -name "install.sh" \
        -print -quit)"

fi

if [[ -z "$ORIGINAL_INSTALLER" || ! -f "$ORIGINAL_INSTALLER" ]]; then
    fail "install.sh was not found inside setup.zip."
fi

chmod +x "$ORIGINAL_INSTALLER"

ok "Original Degeris installer found."

###############################################################################
# INSTALL
###############################################################################

echo
say "[6/6] Starting Degeris $VERSION installer..."
echo

echo "=============================================="
echo "          DEGERIS $VERSION"
echo "=============================================="
echo

cd "$(dirname "$ORIGINAL_INSTALLER")"

bash "$ORIGINAL_INSTALLER"

###############################################################################
# DONE
###############################################################################

echo
echo "=============================================="
echo "        DEGERIS INSTALLER FINISHED"
echo "=============================================="
echo
echo "Installed version: $VERSION"
echo
echo "=============================================="
