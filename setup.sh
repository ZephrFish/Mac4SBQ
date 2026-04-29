#!/usr/bin/env bash
# @decision: Single entry point — the only script the user needs to know about.
# Sources lib/* files rather than calling them as subprocesses so all functions share
# the same environment (MACBEQUICK_LOG, SCRIPT_DIR, color vars). set -euo pipefail
# catches errors early; the EXIT trap ensures the user always gets a diagnostic message
# rather than a silent failure.

set -euo pipefail

# Parse --dry-run flag
DRY_RUN=0
for arg in "$@"; do
    [[ "${arg}" == "--dry-run" ]] && DRY_RUN=1
done
export DRY_RUN

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Log setup ----
MACBEQUICK_DIR="${HOME}/.macbequick"
mkdir -p "${MACBEQUICK_DIR}"
MACBEQUICK_LOG="${MACBEQUICK_DIR}/setup-$(date +%Y%m%d-%H%M%S).log"
export MACBEQUICK_LOG
echo "macbequick setup started at $(date)" > "${MACBEQUICK_LOG}"

# ---- Source libraries ----
# shellcheck source=lib/ui.sh
source "${SCRIPT_DIR}/lib/ui.sh"
# shellcheck source=lib/prereqs.sh
source "${SCRIPT_DIR}/lib/prereqs.sh"
# shellcheck source=lib/apps.sh
source "${SCRIPT_DIR}/lib/apps.sh"
# shellcheck source=lib/terminal.sh
source "${SCRIPT_DIR}/lib/terminal.sh"
# shellcheck source=lib/vscode.sh
source "${SCRIPT_DIR}/lib/vscode.sh"
# shellcheck source=lib/gitconfig.sh
source "${SCRIPT_DIR}/lib/gitconfig.sh"

# ---- EXIT trap: friendly message on unexpected failure ----
_on_exit() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        echo ""
        echo -e "${RED}Setup was interrupted (exit code ${exit_code}).${RESET}"
        echo -e "Check the log for details: ${DIM}${MACBEQUICK_LOG}${RESET}"
        echo "Run setup.sh again to resume — it skips what's already done."
    fi
}
trap '_on_exit' EXIT

# ---- Main ----
main() {
    show_welcome_banner

    check_prereqs

    install_apps

    setup_terminal

    setup_vscode

    setup_gitconfig

    # Guided tour — printed narrative, no blocking prompts
    source "${SCRIPT_DIR}/tour/tour.sh"

    show_finish_message
}

main "$@"
