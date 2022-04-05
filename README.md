# Btcrecover Distro

Btcrecover Distro can be started from a CDROM or an USB stick on a computer and being used to use btcrecover in air gapped linux live environment.  
Use f12 or other keypress at bios boot to select the usb or cdrom to boot. Everything should start automatically and you should arrive to the btcrecover master directory.   
This is very minimal debian distro, I removed network driver to be sure to be airgapped. When finished, power down by long press power button of the PC. (to restart you can do ctrl-alt-f1 to go to console then ctrl-alt-del).
If you want to change the keyboard keymap to other than qwerty, type setxkbmap <2lettercountrycode>


## Setup Btcrecover Distribution  to a CDROM or USB stick

the iso image is hybrid and can be burned to cd or usb.

**CDROM:**  
use your favorite program to burn the ISO to CDROM.
Nothing special. CDROMs are naturally read-only and tamper resistant.

**USB:**  

On windows you can use balena etcher to write the iso to usb.

On linux :

1) Insert USB stick and detect the device path::
```
$ dmesg|grep Attached | tail --lines=1
[583494.891574] sd 19:0:0:0: [sdf] Attached SCSI removable disk
```
2) Write ISO to USB:: (replace sdf by the real device path)
```
$ sudo dd if=path/to/seedsigner_distro.iso of=/dev/sdf
$ lsblk | grep sdf
sdf                                8:80   1   7.4G  1 disk  
└─sdf1                             8:81   1   444M  1 part 
```

## How to build from source

Build is done using vagrant and the distro_build_script.sh script. 

initialise vagrant :

```
$ vagrant up
$ vagrant ssh
```

then build the iso using the script that is in the shared folder /vagrant as root:
```
$ sudo su
$ cd /vagrant
$ ./distro_build_script.sh
```


## Credits

This project was inspired by airgap.it / airgap-distro.  
Seedsigner.appimage is from @kornpow  
latest build script inspired from https://willhaley.com/blog/custom-debian-live-environment/  
