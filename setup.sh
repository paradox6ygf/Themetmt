#!/usr/bin/env bash
# =============================================================================
#  OBSIDIAN THEME - Blueprint Extension Installer
#  Premium dark theme for the Pterodactyl Panel
#
#  Usage:
#    curl -sL https://themetmt.vercel.app -o install.sh && sudo bash install.sh
# =============================================================================
set -euo pipefail

BOLD="\033[1m"
RED="\033[91m"; GREEN="\033[92m"; YELLOW="\033[93m"
LIME="\033[38;5;154m"; WHITE="\033[97m"; GREY="\033[90m"; RESET="\033[0m"

STEP_NUM=0
step() { STEP_NUM=$((STEP_NUM+1)); echo -e "\n${LIME}${BOLD}[$STEP_NUM/6]${RESET} ${WHITE}${BOLD}$1${RESET}"; }
ok()   { echo -e "    ${GREEN}✓${RESET} $1"; }
warn() { echo -e "    ${YELLOW}!${RESET} $1"; }
fail() { echo -e "\n${RED}${BOLD}✗ Installation failed:${RESET} $1"; echo -e "${GREY}Nothing was changed on your panel. Fix the issue above and re-run this installer.${RESET}"; exit 1; }

O1="\033[38;5;22m";  O2="\033[38;5;28m";  O3="\033[38;5;34m"
O4="\033[38;5;40m";  O5="\033[38;5;46m";  O6="\033[38;5;154m"

BANNER_LINES=(
"${O1}  ██████╗ ██████╗ ███████╗██╗██████╗ ██╗ █████╗ ███╗   ██╗${RESET}"
"${O2} ██╔═══██╗██╔══██╗██╔════╝██║██╔══██╗██║██╔══██╗████╗  ██║${RESET}"
"${O3} ██║   ██║██████╔╝███████╗██║██║  ██║██║███████║██╔██╗ ██║${RESET}"
"${O4} ██║   ██║██╔══██╗╚════██║██║██║  ██║██║██╔══██║██║╚██╗██║${RESET}"
"${O5} ╚██████╔╝██████╔╝███████║██║██████╔╝██║██║  ██║██║ ╚████║${RESET}"
"${O6}  ╚═════╝ ╚═════╝ ╚══════╝╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝${RESET}"
)

for line in "${BANNER_LINES[@]}"; do
  echo -e "$line"
  sleep 0.05
done

echo -e "  ${WHITE}${BOLD}Obsidian Theme — premium dark theme for Pterodactyl Panel${RESET}"
echo -e "  ${GREY}Blueprint extension · live admin customizer · one-command install${RESET}"
echo -e "  ${GREY}──────────────────────────────────────────────────────${RESET}"
echo -e ""
echo -e "  ${WHITE}${BOLD}Kʏɹɔɴɪx Hɛɐɕɜɑʀⱬʀ </>${RESET}"
echo -e "  ${GREY}support:${RESET} ${WHITE}https://discord.com/invite/TZmtT5tNmU${RESET}"
echo -e "  ${GREY}dev:${RESET} ${LIME}${BOLD}6fck${RESET} ${GREY}(main)${RESET}   ${GREY}co-dev:${RESET} ${WHITE}dray.me${RESET}"

step "Checking environment"

[ "$(id -u)" -eq 0 ] || fail "This installer must run as root. Try: sudo bash install.sh"
ok "Running as root"

PANEL_DIR="/var/www/pterodactyl"
[ -d "$PANEL_DIR" ] || fail "Pterodactyl Panel not found at $PANEL_DIR."
[ -f "$PANEL_DIR/artisan" ] || fail "$PANEL_DIR exists but is not a Pterodactyl Panel installation."
ok "Pterodactyl Panel found at $PANEL_DIR"

command -v blueprint >/dev/null 2>&1 || [ -x "$PANEL_DIR/blueprint" ] \
  || fail "Blueprint is not installed. Install it first: https://blueprint.zip"
ok "Blueprint detected"

for cmd in curl unzip zip; do
  command -v "$cmd" >/dev/null 2>&1 || fail "Missing dependency: $cmd (install it and re-run)."
done
ok "curl, unzip, zip available"

if [ -x "$PANEL_DIR/blueprint" ]; then BLUEPRINT_CMD="$PANEL_DIR/blueprint"; else BLUEPRINT_CMD="blueprint"; fi

step "Checking for previous installations"

cd "$PANEL_DIR"
DB_FILE=".blueprint/extensions/blueprint/private/db/installed_extensions"
if [ -f "$DB_FILE" ] && grep -q "|kyronixtheme," "$DB_FILE" 2>/dev/null; then
  warn "Legacy kyronixtheme detected — replacing it with Obsidian."
  "$BLUEPRINT_CMD" -r kyronixtheme >/dev/null 2>&1 \
    && ok "Legacy KyronixTheme removed cleanly." \
    || warn "Could not remove legacy KyronixTheme automatically — continuing anyway."
else
  ok "No legacy installation found."
fi

if grep -q "|obsidiantheme," "$DB_FILE" 2>/dev/null; then
  ok "Existing Obsidian Theme found — this run will update it in place."
else
  ok "Fresh install of Obsidian Theme."
fi

step "Downloading Obsidian Theme"

TMP_DIR="$(mktemp -d -t obsidian-XXXXXX)"
cleanup() { rm -rf "$TMP_DIR"; }
trap 'cleanup; echo -e "\n${RED}✗ Installer interrupted. Nothing was changed.${RESET}"' EXIT INT TERM

curl -sSL --retry 3 "https://github.com/paradox6ygf/kyronixTheme/archive/refs/heads/main.zip" -o "$TMP_DIR/theme.zip" \
  || fail "Could not download the theme source from GitHub. Check your internet connection."

[ -s "$TMP_DIR/theme.zip" ] || fail "Downloaded archive is empty — GitHub may be rate-limiting. Wait a minute and re-run."
ok "Downloaded $(du -h "$TMP_DIR/theme.zip" | cut -f1)"

unzip -qq "$TMP_DIR/theme.zip" -d "$TMP_DIR" || fail "Downloaded archive is corrupted."
SRC_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name "*main" | head -1)"
[ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/conf.yml" ] || fail "Downloaded source does not contain an Obsidian Theme extension (conf.yml missing)."
ok "Source verified (conf.yml present)"

step "Packaging Blueprint extension"

( cd "$SRC_DIR" && zip -qr "$TMP_DIR/obsidiantheme.blueprint" . -x "*.git*" ) \
  || fail "Failed to package the extension."
[ -s "$TMP_DIR/obsidiantheme.blueprint" ] || fail "Packaging produced an empty archive."
ok "Packaged obsidiantheme.blueprint"

mv "$TMP_DIR/obsidiantheme.blueprint" "$PANEL_DIR/" || fail "Could not move the package into $PANEL_DIR."
ok "Moved into panel directory"

step "Installing via Blueprint"

cd "$PANEL_DIR"
"$BLUEPRINT_CMD" -install obsidiantheme || {
  rm -f "$PANEL_DIR/obsidiantheme.blueprint"
  fail "Blueprint rejected the installation. Its output above shows the exact reason."
}

rm -f "$PANEL_DIR/obsidiantheme.blueprint"
cleanup
trap - EXIT INT TERM

step "Finalizing"

PANEL_URL=""
if [ -f "$PANEL_DIR/.env" ]; then
  PANEL_URL="$(grep -E "^APP_URL=" "$PANEL_DIR/.env" | head -1 | cut -d= -f2- | sed "s|/*$||")"
fi
PANEL_URL="${PANEL_URL:-https://your-panel-domain}"

echo -e "\n${LIME}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${LIME}${BOLD}  ✓  Obsidian Theme successfully installed!${RESET}"
echo -e "${LIME}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e ""
echo -e "  ${WHITE}${BOLD}Customize the theme${RESET} ${GREY}(admin only)${RESET}:"
echo -e "  ${LIME}${BOLD}${PANEL_URL}/account/customizer${RESET}"
echo -e ""
echo -e "  ${GREY}Colors, radius, animations, density, dark/light — live preview,${RESET}"
echo -e "  ${GREY}changes save instantly.${RESET}"
echo -e ""
echo -e "  ${GREY}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${WHITE}${BOLD}Kʏɹɔɴɪx Hɛɐɕɜɑʀⱬʀ </>${RESET}"
echo -e "  ${GREY}support:${RESET} ${WHITE}https://discord.com/invite/TZmtT5tNmU${RESET}   ${GREY}dev:${RESET} ${LIME}${BOLD}6fck${RESET} ${GREY}(main)${RESET}   ${GREY}co-dev:${RESET} ${WHITE}dray.me${RESET}"
echo -e ""