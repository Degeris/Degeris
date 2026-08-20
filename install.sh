#!/bin/bash
set -euo pipefail

###############################################################################
#                         DEGERIS INSTALLER
#                  GitHub Release Bootstrap Installer
###############################################################################

REPO_OWNER="Degeris"
REPO_NAME="Degeris"
ASSET_NAME="setup.zip"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

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
# ROOT
###############################################################################

if [ "$(id -u)" -ne 0 ]; then
    fail "لطفاً Installer را با دسترسی root اجرا کنید."
fi

###############################################################################
# VERSION
###############################################################################

REQUESTED_VERSION="${1:-}"

###############################################################################
# REQUIRED COMMANDS
###############################################################################

echo "[1/6] بررسی پیش‌نیازها..."

if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then

    echo "در حال نصب curl و unzip..."

    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y curl unzip

    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl unzip

    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl unzip

    else
        fail "Package Manager پشتیبانی‌شده پیدا نشد."
    fi
fi

ok "curl و unzip آماده هستند."

###############################################################################
# TEMP
###############################################################################

TMP_DIR="$(mktemp -d /tmp/degeris-installer.XXXXXX)"

ZIP_FILE="$TMP_DIR/setup.zip"
APP_DIR="$TMP_DIR/app"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

mkdir -p "$APP_DIR"

###############################################################################
# GET VERSION
###############################################################################

echo
echo "[2/6] بررسی نسخه..."

if [ -n "$REQUESTED_VERSION" ]; then

    VERSION="$REQUESTED_VERSION"

    echo
    echo "نسخه انتخاب‌شده:"
    echo "  $VERSION"
    echo

else

    echo "نسخه‌ای مشخص نشده است."
    echo "در حال دریافت آخرین نسخه Degeris..."

    API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

    RELEASE_JSON="$(curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        "$API_URL")" || {
        fail "دریافت آخرین نسخه از GitHub ناموفق بود."
    }

    VERSION="$(printf '%s\n' "$RELEASE_JSON" \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n 1)"

    if [ -z "$VERSION" ]; then
        fail "شماره آخرین نسخه از GitHub دریافت نشد."
    fi

    echo
    ok "آخرین نسخه: $VERSION"
fi

###############################################################################
# VERSION CHECK
###############################################################################

if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then

    echo
    warn "فرمت نسخه دریافت‌شده صحیح نیست:"
    echo "  $VERSION"
    echo
    echo "فرمت صحیح مثال:"
    echo "  1.0.0"
    echo "  1.2.1"
    echo "  1.5.0"
    echo "  2.0.0"
    echo "  4.0.0"
    echo

    fail "Version نامعتبر است."
fi

###############################################################################
# RELEASE URL
###############################################################################

DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${ASSET_NAME}"

echo
echo "=============================================="
echo "             DEGERIS $VERSION"
echo "=============================================="
echo
echo "Release:"
echo "https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/tag/${VERSION}"
echo
echo "Asset:"
echo "$ASSET_NAME"
echo

###############################################################################
# DOWNLOAD
###############################################################################

echo "[3/6] دانلود setup.zip..."

echo

if ! curl -fL \
    --retry 3 \
    --retry-delay 2 \
    --connect-timeout 20 \
    --max-time 0 \
    -o "$ZIP_FILE" \
    "$DOWNLOAD_URL"; then

    echo
    fail "نسخه $VERSION پیدا نشد یا فایل setup.zip در Release وجود ندارد."
fi

if [ ! -s "$ZIP_FILE" ]; then
    fail "فایل setup.zip خالی است."
fi

ok "setup.zip دانلود شد."

###############################################################################
# ZIP TEST
###############################################################################

echo
echo "[4/6] بررسی فایل ZIP..."

if ! unzip -t "$ZIP_FILE" >/dev/null 2>&1; then
    fail "setup.zip خراب یا ناقص است."
fi

ok "ZIP سالم است."

###############################################################################
# EXTRACT
###############################################################################

echo
echo "[5/6] استخراج فایل‌ها..."

unzip -q "$ZIP_FILE" -d "$APP_DIR"

ok "فایل‌ها Extract شدند."

###############################################################################
# FIND INSTALL.SH
###############################################################################

echo
echo "[6/6] پیدا کردن Installer اصلی..."

ORIGINAL_INSTALLER=""

if [ -f "$APP_DIR/install.sh" ]; then
    ORIGINAL_INSTALLER="$APP_DIR/install.sh"
else
    ORIGINAL_INSTALLER="$(find "$APP_DIR" -type f -name "install.sh" -print -quit)"
fi

if [ -z "$ORIGINAL_INSTALLER" ]; then

    echo
    echo "فایل‌های داخل Release:"
    find "$APP_DIR" -maxdepth 3 -type f | head -50
    echo

    fail "install.sh داخل setup.zip نسخه $VERSION پیدا نشد."
fi

chmod +x "$ORIGINAL_INSTALLER"

ok "Installer اصلی پیدا شد:"
echo
echo "  $ORIGINAL_INSTALLER"
echo

###############################################################################
# RUN ORIGINAL INSTALLER
###############################################################################

echo "=============================================="
echo "       شروع نصب Degeris نسخه $VERSION"
echo "=============================================="
echo

INSTALLER_DIR="$(dirname "$ORIGINAL_INSTALLER")"

cd "$INSTALLER_DIR"

bash "$ORIGINAL_INSTALLER"

###############################################################################
# COMPLETE
###############################################################################

echo
echo "=============================================="
echo "        DEGERIS INSTALLATION COMPLETED"
echo "=============================================="
echo
echo "نسخه نصب‌شده: $VERSION"
echo
echo "برای اجرای منوی مدیریت پنل:"
echo
echo "    Degerist"
echo
echo "=============================================="
