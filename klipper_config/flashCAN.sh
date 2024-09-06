#!/bin/bash

## -------------------------------------------------------- HOW TO USE -----------------------------------------------------------
## save this document and copy to your klipper system into the /klipper directory.
## give it a name (eg. flashCAN.sh)
## ssh into your system. go to your klipper directory and run the command: sudo chmod +x flashCAN.sh
## now you can run the script by typing the following command in ssh
## ~/klipper/flashCAN.sh

## make sure to fill in your OWN values for 
## - usb-katapult_your_mainboard_usb_id
## - yourmainboarduuid
## - yourtoolheaduuid

# these are values for me! 
# yourmainboardUUID=403544310df5
# katapult_your_mainboard_usb_id = usb-Klipper_stm32f446xx_380010000B50534E4E313120-if00
# canbus_uuid: 553de26b2beb

## while installing CAN the first time, note your usb-katapult-mainboard-usb-id, mainboard UUID, toolhead UUID. 
## or if you have a functioning CAN network, run ~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 to see a list of installed CAN devices.
## the UUID for mainboard and toolhead you need to put in your printer.cfg file, so you can retrieve it from there.
## But the USB serial ID you have to obtain after you put the mainboard into katapult boot flash mode (STEP 2 A below).

## after  the command  python3 ~/katapult/scripts/flashtool.py -i can0 -u yourmainboarduuid -r 
## you will need to type: "ls /dev/serial/by-id" and it will give you your USB serial ID.

## once you have run through this script, comment out (put a # in front of the line) the line which has the "make menuconfig" in it.
## and the next time you have a klipper update that breaks your CAN, all you have to do, is to run this script once.


#-------------------------------------FINAL WORDS--------------------------------------------------
# this script is for me and my set up.
# HARDWARE
# Raspberry Pi 4B, 8mb
# Voron 2.4, 350
# Octopus Pro mainboard
# SB2209 (RP2040) Big Tree Tech 2 part Toolhead PCB
# Cartographer 3D Eddy Probe in CAN mode
# with built in accelerometer / resonance tester
# The Octopus functions as a CAN bridge. Cartographer 3D is connected to The SB2209 (RP2040). 
# The CAN bus is terminated at the Cartographer 3D probe.

# SOFTWARE:
# OS: Raspbian GNU/Linux 11 (bullseye)
# Distro: MainsailOS 1.2.1 (bullseye)
# klipper: v0.12.0-114-ga77d0790

# if you are not using this script on my system then anything can happen which I am not responsible for.




echo "STEP 1 - UPDATE KATAPULT FROM GIT if needed"
test -e ~/katapult && (cd ~/katapult && git pull) || (cd ~ && git clone https://github.com/Arksine/katapult) ; cd ~

echo "STEP 2a - FLASH MAINBOARD KATAPULT so we can flash it easily"
cd ~/katapult
make clean KCONFIG_CONFIG=config.mainboardKatapult # cleans old files
make menuconfig KCONFIG_CONFIG=config.mainboardKatapult # this can be commented out for automation AFTER you have filled out correct fields for your card. or leave it in to have some control
make KCONFIG_CONFIG=config.mainboardKatapult # this creates a deploy.bin
python3 ~/katapult/scripts/flashtool.py -i can0 -u yourmainboarduuid -r # puts mainboard in katapult flash mode
python3 ~/katapult/scripts/flashtool.py -f ~/katapult/out/deployer.bin -d /dev/serial/by-id/usb-katapult_your_mainboard_usb_id # flashes katapult to mainboard


echo "STEP 2b - FLASH MAINBOARD so it works as a CAN BRIDGE, over KATAPULT"
cd ~/klipper
make clean KCONFIG_CONFIG=config.mainboardUSB2CANbb # cleans old files
make menuconfig KCONFIG_CONFIG=config.mainboardUSB2CANbb # configuration for klipper-U2CBB. comment this line for automation
make KCONFIG_CONFIG=config.mainboardUSB2CANbb # this creates klipper.bin 
sudo service klipper stop
# mainboard still in katapult forced flash mode. so feel free to flash klipper can bridge on it!
python3 ~/katapult/scripts/flashtool.py -f ~/klipper/out/klipper.bin -d /dev/serial/by-id/usb-katapult_yourmainboardusbid # flashes klipper-U2CBB to MAINBOARD
sudo service klipper start


echo "STEP 3a UPDATE TOOLHEAD KATAPULT so we can flash it easily"
cd ~/katapult
make clean KCONFIG_CONFIG=config.toolheadKatapult # clean old files
make menuconfig KCONFIG_CONFIG=config.toolheadKatapult # comment out for full automation after once filled out!
make KCONFIG_CONFIG=config.toolheadKatapult # build katapult deployer.bin
python3 ~/katapult/scripts/flashtool.py -i can0 -u yourtoolheaduuid -r # put toolhead board into katapult flash mode
python3 ~/katapult/scripts/flashtool.py -i can0 -u yourtoolheaduuid -f ~/katapult/out/deployer.bin # flash the katapult binary


echo "STEP 3b UPDATING TOOLHEAD KLIPPER over KATAPULT"
cd ~/klipper
make clean KCONFIG_CONFIG=config.toolheadKlipper
make menuconfig KCONFIG_CONFIG=config.toolheadKlipper
make KCONFIG_CONFIG=config.toolheadKlipper
sudo service klipper stop
python3 ~/katapult/scripts/flashtool.py -i can0 -u yourtoolheaduuid -f ~/klipper/out/klipper.bin
sudo service klipper start

echo " The Klippper update flash script has finished. Hopefully all is working again :-)"