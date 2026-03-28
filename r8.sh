#!/usr/bin/env bash
# =============================================================================
# r8.sh — ISCE2 topsStack Step 8 wrapper
#
# Checks for existing outputs before reprocessing; collects only missing jobs
# and reruns them with optional parallelism.
#
# Usage:
#   bash r8.sh [N_PROCESSORS]
#
# Authors:
#   Manudeo Singh (manudeo.singh@aber.ac.uk)
#   ORCID: 0000-0002-3511-8362
#   Swath/burst detection logic partially adapted from scripts by
#   Bodo Bookhagen (University of Potsdam).
#
# License: MIT — see LICENSE file for details.
# =============================================================================
WORK_DIR=`pwd`

cd $WORK_DIR

rerun_file=run_08_timeseries_misreg

rm $rerun_file*

./run_files/$rerun_file 2>&1 | tee log/$rerun_file.log
