#!/usr/bin/env bash
# =============================================================================
# r10.sh — ISCE2 topsStack Step 10 wrapper
#
# Checks for existing outputs before reprocessing; collects only missing jobs
# and reruns them with optional parallelism.
#
# Usage:
#   bash r10.sh [N_PROCESSORS]
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
rerun_file=rerun_10_missing
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

#=====================================================================
#Run_10
echo 'Start run 10'
cd $WORK_DIR/
sed -i 's/ &//g' run_files/run_10_fullBurst_resample
sed -i '/wait/d' run_files/run_10_fullBurst_resample
sed -i '/^[[:space:]]*$/d' run_files/run_10_fullBurst_resample

wc -l run_files/run_10_fullBurst_resample
mkdir run_10_fullBurst_resample
cd run_10_fullBurst_resample
split -l 1 ../run_files/run_10_fullBurst_resample R10

PROCESS_DIR=$WORK_DIR/run_10_fullBurst_resample
cd $WORK_DIR/
for filename in $WORK_DIR/run_10_fullBurst_resample/R*; do
  file2process=`basename $filename`
  date1=$(grep config_fullBurst_resample_ $WORK_DIR/run_10_fullBurst_resample/$file2process | rev | cut -d / -f 1 | rev | cut -d _ -f 4)
  burst_path1=$WORK_DIR/coreg_secondarys/$date1/$IW_num
  burst_path2=$WORK_DIR/coreg_secondarys/$date1/$IW_num1
  burst_path3=$WORK_DIR/coreg_secondarys/$date1/$IW_num2
  IW_path=$WORK_DIR/coreg_secondarys/$date1/$IW_num.xml
  if [[ -f ${burst_path1}/$burst_num.slc && -f ${burst_path1}/$burst_num.slc.vrt && -f ${burst_path2}/$burst_num1.slc.xml  && -f ${burst_path3}/$burst_num2.slc.xml ]]; then
    echo "${date1} : azimuth and dates exists, skip to next "
    continue
      else
    echo "${date1} burst does not exist, rerun"
  fi;

cat $PROCESS_DIR/$file2process >> $rerun_file.txt
done
sed 's/$/ \&/g' $rerun_file.txt > $rerun_file.sh
sed "0~${processors} s/$/\nwait\n/g" $rerun_file.sh > $rerun_file.cmd

chmod +x $rerun_file.cmd

./$rerun_file.cmd 2>&1 | tee log/$rerun_file.log
