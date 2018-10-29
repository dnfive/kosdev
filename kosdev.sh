#!/bin/bash
# =============================================================================== #
# Description:                                                                    #
#  kosdev - bash script, that: creates, mounts, unmounts,              			  #
#           the ".img" image.                                                     #
#			and starting qemu with KolibriOS									  #
# Usage:                                                                          #
# kosdev create  - to create an image.                                       	  #
# kosdev mount   - to mount the image.                                            #
# koshdd unmount - to unmount the image.                                          #
# kosdev start  - to launch qemu.                                                 #
# =============================================================================== #
# --------------------------------------------                                    #
# Bash script kosdev was written by dnfive.                                    	  #
# --------------------------------------------                                    #
# GNU GPLv2.                                                                      #
# =============================================================================== #

# img name.
imgname='kosdev'

# kolibri image
kosname='kolibri.iso'

# mount dir
mount_dir='/media/kolibri'

# dev path
dev_path=`pwd`

# img size im M
img_size=256

# backup dir
backup_dir='$dev_path/backup'

# RAM usege qemu
kosRAM=256
# =============================================================================== #
# =============================================================================== #
function create_img () {
# create image and format it.
if `test -e "${dev_path}/${imgname}.img"`
then
  echo
  echo "The image \"${imgname}.img\" is alredy exists..."
  echo
  read -n 1 -p "Do you want to recreate an existing one?(y/n) " answer
  case $answer in
    "Y" | "y") sudo rm "${dev_path}/${imgname}.img" ; echo ; make_kosimg ; echo ;;
    "N" | "n") echo ; echo ;;
    *) echo ; echo "Error: wrong answer, try again!"  ; echo ; exit 1 ;;
  esac
else
  make_img
fi
}
# =============================================================================== #
# =============================================================================== #
function make_img () {
# create image and format it.
  echo "Creating the image \"${imgname}.img\"..."
  sudo dd if=/dev/zero of="${dev_path}/${imgname}.img" bs=1M count=${img_size}
  echo "Formatting the image \"${imgname}.img\" in fat32..."
  sudo mkfs.vfat -F 32 "${dev_path}/${imgname}.img"
  sudo chmod -R u+rw "${dev_path}/${imgname}.img" && sudo chmod -R go+r "${dev_path}/${imgname}.img" && sudo chmod -R go-wx "${dev_path}/${imgname}.img"
}

# =============================================================================== #
# =============================================================================== #

function mount_img () {
# create directory.
if ! `test -d ${mount_dir}` ; then
  echo "Creating directory \"${mount_dir}\"..."
  sudo mkdir -p ${mount_dir}
# sudo chmod -R go-x ${mount_dir}/${name}
fi

# mounting image and puting rights.
sudo mount | grep "${mount_dir}" > /dev/null
#if `test $?` ; then
if ! [[ $? -eq 0 ]] ; then
  echo "Mounting \"${imgname}.img\" in ${mount_dir}..."
  sudo mount -t vfat -o loop,uid=1000,rw "${dev_path}/${imgname}.img" ${mount_dir}
  # sudo mount -t vfat -o loop,uid=1000,rw,noexec "${dev_path}/${imgname}.img" ${mount_dir}
  sudo chmod -R ugo+rw ${mount_dir}
else
  echo "The image \"${imgname}.img\" is already mounted..."
fi
}

# =============================================================================== #
# =============================================================================== #

function unmount_img () {
# unmounting the image.
sudo mount | grep "${mount_dir}" > /dev/null
if [[ $? -eq 0 ]] ; then
  echo "Unmounting \"${imgname}.img\" image file..."
  sudo umount "${dev_path}/${imgname}.img"
fi
}

# =============================================================================== #
# =============================================================================== #
function launch_qemu () {
# backuping ".img" to "kos32" directory.
if `test -e "${backup_dir}/${imgname}.img"` ; then
    sudo rm "${backup_dir}/${imgname}.img"
fi
echo "Backuping \"${imgname}.img\" to \"${backup_dir}\"..."
sudo cp "${dev_path}/${imgname}.img" ${backup_dir}

# unmounting directory.
unmount_kosimg

sudo chmod -R u+rw "${dev_path}/${imgname}.img" && sudo chmod -R go+rw "${dev_path}/${imgname}.img" && sudo chmod -R go-x "${dev_path}/${imgname}.img"

# start KolibriOS in qemu.
echo "Starting KolibriOS in qemu..."
qemu-system-x86_64 -hda ${dev_path}/${imgname}.img -boot d -cdrom ${dev_path}/${kosname} -m ${kosRAM}
}
# =============================================================================== #
# =============================================================================== #
function print_usage_info () {
cat <<'EOF'

Usage:
./kosdev create  - to create an image.
./kosdev mount   - to mount the image.
./kosdev start   - to launch qemu.
./kosdev unmount - to unmount the image.

EOF
}

# =============================================================================== #
# =============================================================================== #

# MAIN CODE #

if [[ $# = 1 ]] ; then

  case $1 in
     "create" ) create_img  ;;
     "mount"  ) mount_img   ;;
     "start" ) launch_qemu  ;;
     "unmount") unmount_img ;;
     *) echo ; echo "Error: wrong argument \"$1\", try again!"  ; print_usage_info ; exit 1 ;;
  esac

elif [[ $# = 0 ]]
then echo ; echo "Error: you did not enter any argument!" ; print_usage_info ; exit 1

else echo ; echo "Error: you have entered too many arguments!" ; print_usage_info ; exit 1

fi

exit 0


