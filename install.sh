#!/bin/bash
set -euo pipefail

###############################################################################
#                         DEGERIS INSTALLER
#                    GitHub Release Bootstrap
###############################################################################

REPO="Degeris/Degeris"
ASSET="setup.zip"

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

if [[ "$(id -u)" -ne 0 ]]; then
    fail "لطفاً Installer را با دسترسی root اجرا کنید."
fi

###############################################################################
# VERSION
###############################################################################

REQUESTED_VERSION="${1:-}"

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
# REQUIREMENTS
###############################################################################

echo "[1/6] آماده‌سازی سیستم..."
echo

export DEBIAN_FRONTEND=noninteractive

if command -v apt-get >/dev/null 2>&1; then

    echo "در حال به‌روزرسانی مخازن..."
    apt-get update -y

    echo
    echo "در حال نصب curl و unzip..."
    apt-get install -y curl unzip

elif command -v dnf >/dev/null 2>&1; then

    dnf install -y curl unzip

elif command -v yum >/dev/null 2>&1; then

    yum install -y curl unzip

else

    fail "Package Manager پشتیبانی‌شده پیدا نشد."

fi

command -v curl >/dev/null 2>&1 || fail "curl نصب نشد."
command -v unzip >/dev/null 2>&1 || fail "unzip نصب نشد."

ok "curl و unzip آماده هستند."

###############################################################################
# VERSION SELECTION
###############################################################################

echo
echo "[2/6] بررسی نسخه..."
echo

if [[ -n "$REQUESTED_VERSION" ]]; then

    # هیچ Regex یا محدودیت نسخه‌ای وجود ندارد.
    # هر چیزی که کاربر وارد کند دقیقاً به عنوان Tag استفاده می‌شود.

    VERSION="$REQUESTED_VERSION"

    echo "نسخه انتخاب‌شده:"
    echo
    echo "    $VERSION"
    echo

else

    echo "نسخه‌ای مشخص نشده است."
    echo "در حال پیدا کردن آخرین Release Degeris..."
    echo

    LATEST_URL="https://github.com/${REPO}/releases/latest"

    FINAL_URL="$(
        curl -sS \
            -L \
            --retry 3 \
            --retry-delay 2 \
            --connect-timeout 20 \
            --max-time 60 \
            -o /dev/null \
            -w '%{url_effective}' \
            -A "Mozilla/5.0 Degeris-Installer" \
            "$LATEST_URL" \
            2>/dev/null || true
    )"

    VERSION="$(
        printf '%s\n' "$FINAL_URL" |
        sed -nE 's#^.*/releases/tag/([^/?#]+).*$#\1#p' |
        head -n 1
    )"

    if [[ -z "$VERSION" ]]; then

        echo
        warn "تشخیص خودکار Latest Release موفق نبود."
        echo
        echo "لطفاً شماره نسخه را وارد کنید."
        echo
        echo "مثال:"
        echo "  1.0"
        echo "  1.0.0"
        echo "  1.5"
        echo "  1.5.0"
        echo "  1.52"
        echo "  1.5.2"
        echo "  2.0.0"
        echo "  4.0.0"
        echo

        read -r -p "Version: " VERSION

    fi

fi

###############################################################################
# VERSION CHECK
###############################################################################

if [[ -z "$VERSION" ]]; then
    fail "هیچ نسخه‌ای مشخص نشده است."
fi

# هیچ بررسی فرمت نسخه انجام نمی‌شود.
# 1.52
# 1.5.2
# 1.0
# v1.5.0
# release-1
# هر Tag معتبر GitHub قابل استفاده است.

###############################################################################
# DOWNLOAD URL
###############################################################################

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"

echo
echo "=============================================="
echo "          DEGERIS VERSION: $VERSION"
echo "=============================================="
echo
echo "Release:"
echo "https://github.com/${REPO}/releases/tag/${VERSION}"
echo
echo "Asset:"
echo "$ASSET"
echo

###############################################################################
# DOWNLOAD
###############################################################################

echo "[3/6] دانلود setup.zip..."
echo

if ! curl \
    -fL \
    --retry 5 \
    --retry-delay 3 \
    --connect-timeout 30 \
    --max-time 0 \
    -A "Mozilla/5.0 Degeris-Installer" \
    -o "$ZIP_FILE" \
    "$DOWNLOAD_URL"; then

    echo
    echo "=============================================="
    fail "دانلود نسخه $VERSION ناموفق بود.

آدرس مورد استفاده:

$DOWNLOAD_URL

بررسی کنید:

1. Release با Tag زیر وجود داشته باشد:
   $VERSION

2. داخل Release فایل زیر وجود داشته باشد:
   setup.zip

3. نام Tag دقیقاً با چیزی که وارد کرده‌اید یکی باشد."

fi

if [[ ! -s "$ZIP_FILE" ]]; then
    fail "setup.zip خالی است."
fi

ok "setup.zip دانلود شد."

###############################################################################
# ZIP TEST
###############################################################################

echo
echo "[4/6] بررسی سلامت setup.zip..."
echo

if ! unzip -t "$ZIP_FILE" >/dev/null 2>&1; then

    fail "setup.zip خراب یا ناقص است."

fi

ok "setup.zip سالم است."

###############################################################################
# EXTRACT
###############################################################################

echo
echo "[5/6] استخراج فایل‌ها..."
echo

if ! unzip -q "$ZIP_FILE" -d "$APP_DIR"; then

    fail "استخراج setup.zip ناموفق بود."

fi

ok "فایل‌ها استخراج شدند."

###############################################################################
# FIND INSTALL.SH
###############################################################################

echo
echo "[6/6] پیدا کردن Installer اصلی..."
echo

ORIGINAL_INSTALLER=""

# حالت اول:
if [[ -f "$APP_DIR/install.sh" ]]; then

    ORIGINAL_INSTALLER="$APP_DIR/install.sh"

else

    # حالت دوم:
    # اگر install.sh داخل یک پوشه باشد
    ORIGINAL_INSTALLER="$(
        find "$APP_DIR" \
            -type f \
            -name "install.sh" \
            -print -quit
    )"

fi

if [[ -z "$ORIGINAL_INSTALLER" || ! -f "$ORIGINAL_INSTALLER" ]]; then

    echo
    echo "❌ install.sh داخل setup.zip پیدا نشد."
    echo
    echo "محتویات ZIP:"
    echo

    find "$APP_DIR" -maxdepth 5 -type f -print | head -100

    echo

    fail "Installer اصلی پیدا نشد."

fi

chmod +x "$ORIGINAL_INSTALLER"

ok "Installer اصلی پیدا شد."

###############################################################################
# RUN ORIGINAL INSTALLER
###############################################################################

echo
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
echo
echo "=============================================="
echo "        DEGERIS INSTALLATION COMPLETED"
echo "=============================================="
echo
echo "نسخه نصب‌شده:"
echo
echo "    $VERSION"
echo
echo "برای اجرای منوی مدیریت پنل:"
echo
echo "    Degerist"
echo
echo "=============================================="
