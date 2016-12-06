#!/bin/bash

LOG_FILE=/tmp/sam3-program.log

 
for i in 23 19 18 20 17 27 22 4 
do
  if [ ! -d /sys/class/gpio/gpio$i ]
  then
    echo $i > /sys/class/gpio/export
  fi
done

function super_reset()
{
  #Set EM_Enable
  echo out > /sys/class/gpio/gpio23/direction 

  #Set EM_BOOTMODE
  echo out > /sys/class/gpio/gpio19/direction

  #set EM_nRST
  echo out > /sys/class/gpio/gpio18/direction
  echo out > /sys/class/gpio/gpio20/direction

  #Set TCK
  echo in > /sys/class/gpio/gpio17/direction

  #Set TDO
  echo in > /sys/class/gpio/gpio27/direction

  #Set TDI
  echo in > /sys/class/gpio/gpio22/direction

  #Set TMS
  echo in > /sys/class/gpio/gpio4/direction

  #Set EM_BOOTMODE
  echo out > /sys/class/gpio/gpio18/direction

  #Power OFF 
  echo 0 > /sys/class/gpio/gpio23/value
  echo 1 > /sys/class/gpio/gpio18/value
  echo 1 > /sys/class/gpio/gpio20/value
  echo 1 > /sys/class/gpio/gpio19/value
  sleep 0.5

  #Power ON
  echo 1 > /sys/class/gpio/gpio23/value
  sleep 0.5

  echo 0 > /sys/class/gpio/gpio18/value
  echo 0 > /sys/class/gpio/gpio20/value
  echo 0 > /sys/class/gpio/gpio19/value

  sleep 0.5
  echo 1 > /sys/class/gpio/gpio18/value
  echo 1 > /sys/class/gpio/gpio20/value

  sleep 0.5
  echo 1 > /sys/class/gpio/gpio19/value
}

function reset_mcu() {
  echo out > /sys/class/gpio/gpio18/direction
  echo 1 > /sys/class/gpio/gpio18/value
  echo 0 > /sys/class/gpio/gpio18/value
  echo 1 > /sys/class/gpio/gpio18/value
}

if [[ -f /usr/share/admobilize/matrix-creator/sam3-program.bash.done ]] ; then
    echo "SAM3 MCU was programmed before. Not programming it again."
    exit 0
fi

cd /usr/share/admobilize/matrix-creator

function try_program() {
  reset_mcu
  sleep 0.1

  RES=$(openocd -f cfg/sam3s_rpi_sysfs.cfg 2>&1 | tee ${LOG_FILE} | grep wrote | wc -l)

  echo $RES
}

function check_firmware() {
 COMPARE_VERSION=$(diff <(./firmware_info) <(cat mcu_firmware.version)|wc -l)

 if [ "$COMPARE_VERSION" == "0" ];then
  echo 1
 else #failed
  echo 0 
 fi
}


super_reset 

count=0
while [  $count -lt 30 ]; do
  TEST=$(try_program)
  if [ "$TEST" == "1" ];then
        CHECK=$(check_firmware)
        if [ "$CHECK" == "1" ];then
          echo "****  SAM3 MCU programmed!"
          touch /usr/share/admobilize/matrix-creator/sam3-program.bash.done
          exit 0
        fi
   fi
  let count=count+1
done
echo "**** Could not program SAM3 MCU, you must be check the logfile ${LOG_FILE}"
exit 1
