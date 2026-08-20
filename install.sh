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

info() {
    echo -e "${CYAN}$1${NC}"
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

if [[ "$EUID" -ne 0 ]]; then
    fail "لطفاً این Installer را با دسترسی root اجرا کنید."
fi

###############################################################################
# VERSION
###############################################################################

REQUESTED_VERSION="${1:-}"

###############################################################################
# REQUIRED PACKAGES
###############################################################################

info "[1/6] بررسی پیش‌نیازها..."

export DEBIAN_FRONTEND=noninteractive

if ! command -v curl >/dev/null 2>&1 || \
   ! command -v unzip >/dev/null 2>&1; then

    if command -v apt-get >/dev/null 2>&1; then

        apt-get update -y
        apt-get install -y curl unzip

    elif command -v dnf >/dev/null 2>&1; then

        dnf install -y curl unzip

    elif command -v yum >/dev/null 2>&1; then

        yum install -y curl unzip

    else

        fail "Package manager پشتیبانی‌شده پیدا نشد."

    fi
fi

ok "پیش‌نیازها آماده هستند."

###############################################################################
# TEMP DIRECTORY
###############################################################################

TMP_DIR="$(mktemp -d -t degeris-installer-XXXXXXXX)"

ZIP_FILE="$TMP_DIR/setup.zip"
APP_DIR="$TMP_DIR/app"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

mkdir -p "$APP_DIR"

###############################################################################
# SELECT VERSION
###############################################################################

info "[2/6] انتخاب نسخه..."

if [[ -n "$REQUESTED_VERSION" ]]; then

    VERSION="$REQUESTED_VERSION"

    echo
    echo "نسخه انتخاب‌شده: $VERSION"
    echo

else

    info "نسخه‌ای مشخص نشده است."
    info "در حال پیدا کردن آخرین نسخه Degeris..."

    API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

    RELEASE_JSON="$(
        curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        "$API_URL" \
        2>/dev/null
    )" || fail "دریافت آخرین نسخه از GitHub ناموفق بود."

    VERSION="$(
        printf '%s' "$RELEASE_JSON" |
        grep -m1 '"tag_name"' |
        sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/'
    )"

    if [[ -z "$VERSION" ]]; then
        fail "شماره آخرین نسخه از GitHub دریافت نشد."
    fi

    echo
    ok "آخرین نسخه: $VERSION"
    echo

fi

###############################################################################
# VERSION VALIDATION
###############################################################################

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "فرمت نسخه نامعتبر است: $VERSION

فرمت صحیح مثال:

1.0.0
1.2.1
1.5.0
2.0.0
4.0.0"
fi

###############################################################################
# DIRECT RELEASE URL
###############################################################################

DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${ASSET_NAME}"

echo "=============================================="
echo "              DEGERIS $VERSION"
echo "=============================================="
echo
echo "نسخه: $VERSION"
echo
echo "در حال دانلود:"
echo "$DOWNLOAD_URL"
echo

###############################################################################
# DOWNLOAD
###############################################################################

info "[3/6] دانلود setup.zip..."

if ! curl -fL \
    --retry 3 \
    --retry-delay 2 \
    --connect-timeout 15 \
    --max-time 0 \
    "$DOWNLOAD_URL" \
    -o "$ZIP_FILE"; then

    echo
    fail "نسخه $VERSION پیدا نشد یا setup.zip این نسخه وجود ندارد."
fi

if [[ ! -s "$ZIP_FILE" ]]; then
    fail "فایل setup.zip خالی است."
fi

ok "دانلود نسخه $VERSION انجام شد."

###############################################################################
# CHECK ZIP
###############################################################################

info "[4/6] بررسی setup.zip..."

if ! unzip -t "$ZIP_FILE" >/dev/null 2>&1; then
    fail "setup.zip خراب یا نامعتبر است."
fi

ok "setup.zip سالم است."

###############################################################################
# EXTRACT
###############################################################################

info "[5/6] استخراج فایل‌های نسخه $VERSION..."

unzip -q "$ZIP_FILE" -d "$APP_DIR"

ok "فایل‌ها استخراج شدند."

###############################################################################
# FIND INSTALLER
###############################################################################

ORIGINAL_INSTALLER=""

if [[ -f "$APP_DIR/install.sh" ]]; then

    ORIGINAL_INSTALLER="$APP_DIR/install.sh"

else

    ORIGINAL_INSTALLER="$(
        find "$APP_DIR" \
        -type f \
        -name "install.sh" \
        -print -quit
    )"

fi

if [[ -z "$ORIGINAL_INSTALLER" || ! -f "$ORIGINAL_INSTALLER" ]]; then
    fail "فایل install.sh داخل setup.zip نسخه $VERSION پیدا نشد."
fi

chmod +x "$ORIGINAL_INSTALLER"

ok "Installer نسخه $VERSION پیدا شد."

###############################################################################
# RUN ORIGINAL INSTALLER
###############################################################################

echo
echo "=============================================="
echo "        شروع نصب Degeris $VERSION"
echo "=============================================="
echo

cd "$(dirname "$ORIGINAL_INSTALLER")"

bash "$ORIGINAL_INSTALLER"

###############################################################################
# FINISHED
###############################################################################

echo
echo "=============================================="
echo "          DEGERIS INSTALLATION"
echo "                COMPLETED"
echo "=============================================="
echo
echo "نسخه نصب‌شده: $VERSION"
echo
echo "برای ورود به منوی مدیریت پنل، دستور زیر را وارد کنید:"
echo
echo "    Degerist"
echo
echo "=============================================="
