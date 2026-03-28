#!/usr/bin/env bash
# =============================================================================
# r5.sh — ISCE2 topsStack Step 5 wrapper
#
# Checks for existing outputs before reprocessing; collects only missing jobs
# and reruns them with optional parallelism.
#
# Usage:
#   bash r5.sh [N_PROCESSORS]
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
rerun_file=rerun_05_missing
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
#============================
#Run_05
echo 'Start run 05'
cd $WORK_DIR/
sed -i 's/ &//g' run_files/run_05_overlap_geo2rdr
sed -i '/wait/d' run_files/run_05_overlap_geo2rdr
sed -i '/^[[:space:]]*$/d' run_files/run_05_overlap_geo2rdr

wc -l run_files/run_05_overlap_geo2rdr
mkdir run_05_overlap_geo2rdr
cd run_05_overlap_geo2rdr
split -l 1 ../run_files/run_05_overlap_geo2rdr R05

PROCESS_DIR=$WORK_DIR/run_05_overlap_geo2rdr
cd $WORK_DIR/
for filename in $WORK_DIR/run_05_overlap_geo2rdr/R*; do
  file2process=`basename $filename`
  single_date=$(grep config_overlap_geo2rdr_ $WORK_DIR/run_05_overlap_geo2rdr/$file2process | rev | cut -d / -f 1 | rev | cut -d _ -f 4)
  date_pair_path_ifg=$WORK_DIR/coreg_secondarys/$single_date/overlap/$IW_num/
  date_pair_path_ifg1=$WORK_DIR/coreg_secondarys/$single_date/overlap/$IW_num1/
  date_pair_path_ifg2=$WORK_DIR/coreg_secondarys/$single_date/overlap/$IW_num2/

  if [[ -f ${date_pair_path_ifg}/range_top_01_02.off.vrt && -f ${date_pair_path_ifg}/$azimuth_bot_num.off.vrt && -f ${date_pair_path_ifg1}/range_top_01_02.off.vrt && -f ${date_pair_path_ifg1}/$azimuth_bot_num1.off.vrt &&  -f ${date_pair_path_ifg2}/range_top_01_02.off.vrt && -f ${date_pair_path_ifg2}/$azimuth_bot_num2.off.vrt ]]; then
    echo "$single_date: range_top, range_bot, azimuth_top, azimuth_bot offsets exists, skip to next"
    continue
  else
    echo "$single_date: range_top, range_bot, azimuth_top, azimuth_bot do not exist, rerun"
    if [ ! -f $WORK_DIR/secondarys/$single_date/$IW_num.xml ]; then
      echo "$single_date: secondarys does not exist"
    fi;
  fi;
cat $PROCESS_DIR/$file2process >> $rerun_file.txt
done
sed 's/$/ \&/g' $rerun_file.txt > $rerun_file.sh
sed "0~${processors} s/$/\nwait\n/g" $rerun_file.sh > $rerun_file.cmd

chmod +x $rerun_file.cmd

./$rerun_file.cmd 2>&1 | tee log/$rerun_file.log
