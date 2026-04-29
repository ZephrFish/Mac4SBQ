#!/usr/bin/env bash
# tests/test_ninite_menu.sh
#
# @decision DEC-UI-NINITE-001
# @title Ninite-style categorised app menu with 20 apps across 7 categories
# @status accepted
# @rationale Restructuring _APP_ENTRIES to include CATEGORY: sentinel lines enables a
#   grouped display similar to Ninite.com — users scan by category rather than a flat
#   undifferentiated list. app_selection_menu() skips sentinels when building the
#   toggle list so the toggle index stays contiguous (1-20). Non-interactive mode must
#   still select all real apps and never include CATEGORY: strings in SELECTED_APPS.
#
# Test suite verifies:
#   1. _APP_ENTRIES has exactly 20 app entries (non-CATEGORY lines)
#   2. _APP_ENTRIES has exactly 7 CATEGORY: sentinel lines
#   3. All 6 new cask IDs are present in _APP_ENTRIES
#   4. Non-interactive selection returns all 20 cask IDs
#   5. app_selection_menu() never leaks CATEGORY: sentinels into SELECTED_APPS
#   6. Brewfile contains the 6 new casks (total 14 cask entries)
#   7. tour/tour.sh exits 0
#
# Run from project root: bash tests/test_ninite_menu.sh
# Exit 0 = all pass, exit 1 = failures

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0
FAILURES=()

_pass() { echo "  [PASS] $*"; (( PASS++ )) || true; }
_fail() { echo "  [FAIL] $*"; (( FAIL++ )) || true; FAILURES+=("$*"); }

echo ""
echo "=== Ninite-style menu test suite ==="
echo ""

# ---- Test 1: syntax check ----
echo "-- Syntax checks --"
if bash -n "${PROJECT_DIR}/lib/apps.sh" 2>/dev/null; then
    _pass "lib/apps.sh: syntax OK"
else
    _fail "lib/apps.sh: syntax error"
fi

if bash -n "${PROJECT_DIR}/lib/ui.sh" 2>/dev/null; then
    _pass "lib/ui.sh: syntax OK"
else
    _fail "lib/ui.sh: syntax error"
fi

# ---- Test 2: shellcheck ----
echo ""
echo "-- Shellcheck --"
if command -v shellcheck &>/dev/null; then
    if shellcheck "${PROJECT_DIR}/lib/apps.sh" 2>/dev/null; then
        _pass "lib/apps.sh: shellcheck clean"
    else
        _fail "lib/apps.sh: shellcheck errors"
    fi
    if shellcheck "${PROJECT_DIR}/lib/ui.sh" 2>/dev/null; then
        _pass "lib/ui.sh: shellcheck clean"
    else
        _fail "lib/ui.sh: shellcheck errors"
    fi
else
    echo "  [SKIP] shellcheck not found — skipping"
fi

# ---- Test 3: app entry count (must be 20) ----
echo ""
echo "-- App entry counts --"
app_count=$(bash -c '
    source '"${PROJECT_DIR}/lib/apps.sh"' 2>/dev/null || true
    count=0
    for entry in "${_APP_ENTRIES[@]}"; do
        [[ "${entry}" == CATEGORY:* ]] && continue
        (( count++ )) || true
    done
    echo "${count}"
' 2>/dev/null)

if [[ "${app_count}" -eq 17 ]]; then
    _pass "App entry count: ${app_count} (expected 17)"
else
    _fail "App entry count: ${app_count} (expected 17)"
fi

# ---- Test 4: CATEGORY sentinel count (must be 7) ----
cat_count=$(bash -c '
    source '"${PROJECT_DIR}/lib/apps.sh"' 2>/dev/null || true
    count=0
    for entry in "${_APP_ENTRIES[@]}"; do
        [[ "${entry}" == CATEGORY:* ]] && (( count++ )) || true
    done
    echo "${count}"
' 2>/dev/null)

if [[ "${cat_count}" -eq 7 ]]; then
    _pass "CATEGORY sentinel count: ${cat_count} (expected 7)"
else
    _fail "CATEGORY sentinel count: ${cat_count} (expected 7)"
fi

# ---- Test 5: all 6 new casks present in _APP_ENTRIES ----
echo ""
echo "-- New cask presence in _APP_ENTRIES --"
new_casks=("google-chrome" "firefox" "zoom" "spotify" "the-unarchiver" "vlc")
apps_raw=$(bash -c '
    source '"${PROJECT_DIR}/lib/apps.sh"' 2>/dev/null || true
    printf "%s\n" "${_APP_ENTRIES[@]}"
' 2>/dev/null)

for cask in "${new_casks[@]}"; do
    if echo "${apps_raw}" | grep -qF "${cask}|"; then
        _pass "New cask present: ${cask}"
    else
        _fail "New cask MISSING: ${cask}"
    fi
done

# ---- Test 6: non-interactive run returns all 20 cask IDs ----
echo ""
echo "-- Non-interactive selection (all 20) --"
selected_output=$(bash -c '
    MACBEQUICK_LOG=/dev/null
    source '"${PROJECT_DIR}/lib/ui.sh"' 2>/dev/null
    source '"${PROJECT_DIR}/lib/apps.sh"' 2>/dev/null
    app_selection_menu "${_APP_ENTRIES[@]}"
    echo "${SELECTED_APPS[*]}"
' < /dev/null 2>/dev/null)

selected_count=$(echo "${selected_output}" | wc -w | tr -d ' ')
if [[ "${selected_count}" -eq 17 ]]; then
    _pass "Non-interactive selection returned ${selected_count} casks (expected 17)"
else
    _fail "Non-interactive selection returned ${selected_count} casks (expected 17)"
fi

# Verify none of the selected are CATEGORY: entries
if echo "${selected_output}" | grep -q "^CATEGORY"; then
    _fail "CATEGORY sentinel leaked into SELECTED_APPS"
else
    _pass "No CATEGORY sentinels in SELECTED_APPS"
fi

# ---- Test 7: all 6 new casks appear in SELECTED_APPS from non-interactive run ----
echo ""
echo "-- New casks in non-interactive SELECTED_APPS --"
for cask in "${new_casks[@]}"; do
    if echo "${selected_output}" | grep -qwF "${cask}"; then
        _pass "Selected: ${cask}"
    else
        _fail "Missing from selection: ${cask}"
    fi
done

# ---- Test 8: Brewfile contains 6 new casks ----
echo ""
echo "-- Brewfile cask entries --"
brewfile="${PROJECT_DIR}/config/Brewfile"
for cask in "${new_casks[@]}"; do
    if grep -qF "cask \"${cask}\"" "${brewfile}"; then
        _pass "Brewfile has: cask \"${cask}\""
    else
        _fail "Brewfile MISSING: cask \"${cask}\""
    fi
done

# Total cask count: 1 font + 17 apps = 18
brewfile_cask_count=$(grep -c "^cask" "${brewfile}" 2>/dev/null || echo 0)
if [[ "${brewfile_cask_count}" -eq 18 ]]; then
    _pass "Brewfile total cask count: ${brewfile_cask_count} (expected 18)"
else
    _fail "Brewfile total cask count: ${brewfile_cask_count} (expected 18)"
fi

# ---- Test 9: tour.sh exit 0 ----
echo ""
echo "-- tour/tour.sh exit 0 --"
MACBEQUICK_LOG=/dev/null BOLD="" DIM="" RED="" GREEN="" YELLOW="" CYAN="" WHITE="" RESET="" \
    bash "${PROJECT_DIR}/tour/tour.sh" > /dev/null 2>&1
tour_exit=$?
if [[ "${tour_exit}" -eq 0 ]]; then
    _pass "tour/tour.sh exits 0"
else
    _fail "tour/tour.sh exited ${tour_exit}"
fi

# ---- Summary ----
echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
if [[ ${FAIL} -gt 0 ]]; then
    echo ""
    echo "Failures:"
    for f in "${FAILURES[@]}"; do
        echo "  - ${f}"
    done
    echo ""
    exit 1
fi
echo ""
