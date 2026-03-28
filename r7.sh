#!/usr/bin/env bash
# =============================================================================
# r7.sh — ISCE2 topsStack Step 7 wrapper
#
# Checks for existing outputs before reprocessing; collects only missing jobs
# and reruns them with optional parallelism.
#
# Usage:
#   bash r7.sh [N_PROCESSORS]
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
rerun_file=rerun_07_missing
rm $rerun_file.*
processors=$1
if [[ -z $processors ]]; then processors=1; fi
echo "parallel processes: $processors"

foo=$(grep -m1 config_baseline_ $WORK_DIR/run_files/run_03_average_baseline | cut -d " " -f 3)
reference_date=$(grep baselines $foo | rev | cut -d / -f 1 | rev | cut -d _ -f 1)
echo "Reference date is: ${reference_date}"

#get swath number - if more than 1 swath, IW_num takes last and IW_num1 takes first swath and IW_num2 takes 2nd swath values
IW_num=$(ls $WORK_DIR/reference/ -g | grep "IW." | tail -1 | rev | cut -d ' ' -f 1 | rev | cut -d . -f 1)
IW_num1=$(ls $WORK_DIR/reference/ -g | grep "IW." | head -1 | rev | cut -d ' ' -f 1 | rev | cut -d . -f 1)
#for 2nd swath
if [ $(ls $WORK_DIR/reference/*xml | wc -l) -eq 3 ]; then IW_num2=IW2; else IW_num2=$(ls $WORK_DIR/reference/ -g | grep "IW." | tail -1 | rev | cut -d ' ' -f 1 | rev | cut -d . -f 1); fi

#get number of bursts. Sometimes burst number in different swath varies, therefore, added 3 variables, each for each swath
num=$(ls $WORK_DIR/reference/$IW_num | wc -l)
last_burst_num=$(($num/2))

num1=$(ls $WORK_DIR/reference/$IW_num1 | wc -l)
last_burst_num1=$((${num1}/2))

num2=$(ls $WORK_DIR/reference/$IW_num2 | wc -l)
last_burst_num2=$((${num2}/2))

second_last_burst=$((last_burst_num-1))
second_last_burst1=$((last_burst_num1-1))
second_last_burst2=$((last_burst_num2-1))

#ensure that file names have 05 type of formate and not just '5' in burst_05, needed for bursts less than 10

if [ $last_burst_num -lt 10 ]; then last_burst_num="0$last_burst_num"; fi
if [ $last_burst_num1 -lt 10 ]; then last_burst_num1="0$last_burst_num1"; fi
if [ $last_burst_num2 -lt 10 ]; then last_burst_num2="0$last_burst_num2"; fi

if [ $second_last_burst -lt 10 ]; then second_last_burst="0$second_last_burst"; fi
if [ $second_last_burst1 -lt 10 ]; then second_last_burst1="0$second_last_burst1"; fi
if [ $second_last_burst2 -lt 10 ]; then second_last_burst2="0$second_last_burst2"; fi

burst_num=burst_${last_burst_num}
burst_num1=burst_${last_burst_num1}
burst_num2=burst_${last_burst_num2}

azimuth_bot_num=azimuth_bot_${second_last_burst}_${last_burst_num}
burst_bot_num=burst_bot_${second_last_burst}_${last_burst_num}

azimuth_num=azimuth_${last_burst_num}
range_num=range_${last_burst_num}

azimuth_bot_num1=azimuth_bot_${second_last_burst1}_${last_burst_num1}
burst_bot_num1=burst_bot_${second_last_burst1}_${last_burst_num1}

azimuth_num1=azimuth_${last_burst_num1}
range_num1=range_${last_burst_num1}

azimuth_bot_num2=azimuth_bot_${second_last_burst2}_${last_burst_num2}
burst_bot_num2=burst_bot_${second_last_burst2}_${last_burst_num2}

azimuth_num2=azimuth_${last_burst_num2}
range_num2=range_${last_burst_num2}

#=============================================
#Run_07
echo 'Start run 07'
cd $WORK_DIR/
sed -i 's/ &//g' run_files/run_07_pairs_misreg
sed -i '/wait/d' run_files/run_07_pairs_misreg
sed -i '/^[[:space:]]*$/d' run_files/run_07_pairs_misreg

wc -l run_files/run_07_pairs_misreg
mkdir run_07_pairs_misreg
cd run_07_pairs_misreg
split -l 1 ../run_files/run_07_pairs_misreg R07

PROCESS_DIR=$WORK_DIR/run_07_pairs_misreg
cd $WORK_DIR/
for filename in $WORK_DIR/run_07_pairs_misreg/R*; do
  file2process=`basename $filename`
  date_pair=$(grep config_misreg_ $WORK_DIR/run_07_pairs_misreg/$file2process | rev | cut -d / -f 1 | rev | cut -d _ -f 3,4)
  date_pair_path_ifg=$WORK_DIR/coarse_interferograms/$date_pair
  date_pair_path_az=$WORK_DIR/misreg/azimuth/pairs/$date_pair
  date_pair_path_rg=$WORK_DIR/misreg/range/pairs/$date_pair
  if [[ -f ${date_pair_path_ifg}/overlap/${IW_num1}_top.xml && -f ${date_pair_path_ifg}/overlap/${IW_num1}_bottom.xml && -f ${date_pair_path_ifg}/overlap/${IW_num2}_top.xml && -f ${date_pair_path_ifg}/overlap/${IW_num2}_bottom.xml && -f ${date_pair_path_ifg}/overlap/${IW_num}_top.xml && -f ${date_pair_path_ifg}/overlap/${IW_num}_bottom.xml && -f ${date_pair_path_az}/${date_pair}.txt && -f ${date_pair_path_rg}/${date_pair}.txt ]]; then
    echo "$date_pair: misreg and overlap exist, skip to next"
    continue
  else
    echo "$date_pair: misreg and overlap does not exist, rerun"
  fi;
cat $PROCESS_DIR/$file2process >> $rerun_file.txt
done
sed 's/$/ \&/g' $rerun_file.txt > $rerun_file.sh
sed "0~${processors} s/$/\nwait\n/g" $rerun_file.sh > $rerun_file.cmd

chmod +x $rerun_file.cmd

./$rerun_file.cmd 2>&1 | tee log/$rerun_file.log
