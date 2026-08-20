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

if [ "$(id -u)" -ne 0 ]; then
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

if command -v apt-get >/dev/null 2>&1; then

    echo "در حال به‌روزرسانی مخازن..."

    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y

    echo
    echo "در حال بررسی curl و unzip..."

    apt-get install -y curl unzip

elif command -v dnf >/dev/null 2>&1; then

    dnf install -y curl unzip

elif command -v yum >/dev/null 2>&1; then

    yum install -y curl unzip

else

    fail "Package Manager پشتیبانی‌شده پیدا نشد."

fi

if ! command -v curl >/dev/null 2>&1; then
    fail "curl نصب نشد."
fi

if ! command -v unzip >/dev/null 2>&1; then
    fail "unzip نصب نشد."
fi

ok "پیش‌نیازها آماده هستند."

###############################################################################
# VERSION SELECTION
###############################################################################

echo
echo "[2/6] انتخاب نسخه..."
echo

if [ -n "$REQUESTED_VERSION" ]; then

    VERSION="$REQUESTED_VERSION"

    echo "نسخه انتخاب‌شده:"
    echo
    echo "  $VERSION"
    echo

else

    echo "نسخه‌ای مشخص نشده است."
    echo "در حال پیدا کردن آخرین Release..."

    LATEST_URL="https://github.com/${REPO}/releases/latest"

    FINAL_URL="$(
        curl -sSIL \
            --connect-timeout 20 \
            --max-time 30 \
            -o /dev/null \
            -w '%{url_effective}' \
            "$LATEST_URL" \
            2>/dev/null || true
    )"

    VERSION="$(
        printf '%s\n' "$FINAL_URL" |
        sed -nE 's#^.*/releases/tag/([^/?#]+).*$#\1#p' |
        head -n 1
    )"

    if [ -z "$VERSION" ]; then

        echo
        warn "آخرین نسخه به‌صورت خودکار تشخیص داده نشد."
        echo

        read -r -p "شماره نسخه را وارد کنید (مثلاً 1.5.0): " VERSION

        if [ -z "$VERSION" ]; then
            fail "هیچ نسخه‌ای انتخاب نشد."
        fi

    else

        echo
        ok "آخرین نسخه: $VERSION"

    fi
fi

###############################################################################
# VERSION VALIDATION
###############################################################################

if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then

    echo
    echo "نسخه واردشده:"
    echo "$VERSION"
    echo

    fail "فرمت نسخه نامعتبر است.

نمونه صحیح:
1.0.0
1.1.0
1.2.1
1.5.0
2.0.0
4.0.0"

fi

###############################################################################
# DOWNLOAD URL
###############################################################################

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"

echo
echo "=============================================="
echo "             DEGERIS $VERSION"
echo "=============================================="
echo
echo "در حال دانلود:"
echo
echo "$DOWNLOAD_URL"
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
    fail "دانلود نسخه $VERSION ناموفق بود.

بررسی کنید:
- Release با Tag $VERSION وجود داشته باشد.
- فایل $ASSET داخل Release وجود داشته باشد."

fi

if [ ! -s "$ZIP_FILE" ]; then
    fail "فایل setup.zip خالی است."
fi

ok "setup.zip دانلود شد."

###############################################################################
# ZIP TEST
###############################################################################

echo
echo "[4/6] بررسی سلامت فایل..."

if ! unzip -t "$ZIP_FILE" >/dev/null 2>&1; then
    fail "setup.zip خراب یا ناقص است."
fi

ok "فایل ZIP سالم است."

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
# FIND ORIGINAL INSTALLER
###############################################################################

echo
echo "[6/6] پیدا کردن Installer اصلی..."
echo

ORIGINAL_INSTALLER=""

if [ -f "$APP_DIR/install.sh" ]; then

    ORIGINAL_INSTALLER="$APP_DIR/install.sh"

else

    ORIGINAL_INSTALLER="$(
        find "$APP_DIR" \
            -type f \
            -name "install.sh" \
            -print -quit
    )"

fi

if [ -z "$ORIGINAL_INSTALLER" ] || [ ! -f "$ORIGINAL_INSTALLER" ]; then

    echo
    echo "فایل‌های موجود در setup.zip:"
    echo

    find "$APP_DIR" -maxdepth 4 -type f | head -100

    echo

    fail "install.sh داخل setup.zip نسخه $VERSION پیدا نشد."

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
