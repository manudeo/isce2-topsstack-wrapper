#!/usr/bin/env bash
# =============================================================================
# run_pipeline.sh — ISCE2 topsStack Step un_pipeline wrapper
#
# Checks for existing outputs before reprocessing; collects only missing jobs
# and reruns them with optional parallelism.
#
# Usage:
#   bash run_pipeline.sh [N_PROCESSORS]
#
# Authors:
#   Manudeo Singh (manudeo.singh@aber.ac.uk)
#   ORCID: 0000-0002-3511-8362
#   Swath/burst detection logic partially adapted from scripts by
#   Bodo Bookhagen (University of Potsdam).
#
# License: MIT — see LICENSE file for details.
# =============================================================================
#!/usr/bin/env bash
# =============================================================================
# run_pipeline.sh
# Master wrapper: runs ISCE2 topsStack steps 2–16 in sequence.
#
# Usage:
#   bash run_pipeline.sh [N_PROCESSORS]
#
# N_PROCESSORS  Number of parallel jobs for parallelisable steps (default: 1).
#               Steps 4, 8, and 11 always run serially.
#
# Author: Manudeo Singh (manudeo.singh@aber.ac.uk)
# License: MIT
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROCESSORS=${1:-1}

echo "========================================================"
echo " ISCE2 topsStack Pipeline Wrapper"
echo " Working directory : $(pwd)"
echo " Script directory  : ${SCRIPT_DIR}"
echo " Parallel processes: ${PROCESSORS}"
echo "========================================================"
echo ""

# Ensure log directory exists
mkdir -p log

run_step() {
    local step_script="$1"
    local label="$2"
    local parallel="${3:-true}"

    echo ""
    echo "--------------------------------------------------------"
    echo " Starting: ${label}"
    echo "--------------------------------------------------------"

    if [ "$parallel" = "true" ]; then
        bash "${SCRIPT_DIR}/${step_script}" "${PROCESSORS}"
    else
        bash "${SCRIPT_DIR}/${step_script}"
    fi

    echo " Finished: ${label}"
}

run_step r2.sh  "Step 02 — Unpack secondary SLCs"         true
run_step r3.sh  "Step 03 — Average baseline"               true
run_step r4.sh  "Step 04 — Extract burst overlaps"         false
run_step r5.sh  "Step 05 — Overlap geo2rdr"                true
run_step r6.sh  "Step 06 — Overlap resample"               true
run_step r7.sh  "Step 07 — Pairs misregistration"          true
run_step r8.sh  "Step 08 — Timeseries misregistration"     false
run_step r9.sh  "Step 09 — Full-burst geo2rdr"             true
run_step r10.sh "Step 10 — Full-burst resample"            true
run_step r11.sh "Step 11 — Extract stack valid region"     false
run_step r12.sh "Step 12 — Merge reference/secondary SLCs" true
run_step r13.sh "Step 13 — Generate burst interferograms"  true
run_step r14.sh "Step 14 — Merge burst interferograms"     true
run_step r15.sh "Step 15 — Filter and coherence"           true
run_step r16.sh "Step 16 — Unwrap interferograms"          true

echo ""
echo "========================================================"
echo " Pipeline complete."
echo "========================================================"
