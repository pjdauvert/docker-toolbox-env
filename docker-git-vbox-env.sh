#!/bin/bash

# Shell colors
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[1;97m'
NC='\033[0m'

#Docker VM defaults
DOCKER_VBOX_MEMORY=1024
DOCKER_VBOX_CPU=1
DOCKER_VBOX_DISK=5000

trap '[ "$?" -eq 0 ] || read -p "Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

#Check if docker-machine and VBoxManage exist.
#Install documentation is here: https://docs.docker.com/toolbox/toolbox_install_windows/
STEP="Looking for VBoxManage.exe"
if [ -n "$VBOX_MSI_INSTALL_PATH" ]; then
  VBOXMANAGE="${VBOX_MSI_INSTALL_PATH}VBoxManage.exe"
else
  VBOXMANAGE="${VBOX_INSTALL_PATH}VBoxManage.exe"
fi
if [ ! -f "$VBOXMANAGE" ]; then
  echo "VirtualBox is not installed. Please re-run the Toolbox Installer and try again."
  exit 1
fi
STEP="Checking Docker Toolbox path"
if [ -z "$DOCKER_TOOLBOX_INSTALL_PATH" ]; then
  echo "Docker Toolbox is not found, DOCKER_TOOLBOX_INSTALL_PATH should be set."
  exit 1
else
  # Transform path git style
  DOCKER_TOOLBOX_INSTALL_PATH="$(echo $DOCKER_TOOLBOX_INSTALL_PATH | sed -e 's#\\#/#g' -e 's#\$#/\\$#g' -e 's#^\([a-zA-Z]\):#/\L\1#')"
  DOCKER_MACHINE="${DOCKER_TOOLBOX_INSTALL_PATH}/docker-machine.exe"
fi
STEP="Checking docker-machine"
if [ ! -f "$DOCKER_MACHINE" ]; then
  echo "VirtualBox is not installed. Please re-run the Toolbox Installer and try again."
  exit 1
fi

#Setting docker virtual machine for the project
STEP="Setting up virtual machine for docker"

# ${PWD##*/} returns the current directory, spaces are replaced by '_'.
VM="$(echo ${PWD##*/} | sed -e 's# #_#g')"

"$VBOXMANAGE" list vms | grep \"$VM\" &> /dev/null
VM_EXISTS_CODE=$?

set -e

STEP="Checking existing VM"
if [ "$VM_EXISTS_CODE" -eq 1 ]; then
  echo -e "${RED}$VM VM already existing. Cleaning...${NC}"
  "$DOCKER_MACHINE" rm -f $VM &> /dev/null || :
  rm -rf ~/.docker/machine/machines/$VM

  #set proxy variables if they exists
  if [ -n "${HTTP_PROXY+x}" ]; then
  PROXY_ENV="$PROXY_ENV --engine-env HTTP_PROXY=$HTTP_PROXY"
  fi
  if [ -n "${HTTPS_PROXY+x}" ]; then
  PROXY_ENV="$PROXY_ENV --engine-env HTTPS_PROXY=$HTTPS_PROXY"
  fi
  if [ -n "${NO_PROXY+x}" ]; then
  PROXY_ENV="$PROXY_ENV --engine-env NO_PROXY=$NO_PROXY"
  fi

  echo -e "${GREEN}Creation of a new $VM Vbox${NC}"
  "$DOCKER_MACHINE" create -d virtualbox --virtualbox-memory $DOCKER_VBOX_MEMORY --virtualbox-cpu-count $DOCKER_VBOX_CPU --virtualbox-disk-size $DOCKER_VBOX_DISK $PROXY_ENV $VM
  STEP="Adding local folder to VM"
  echo -e "${GREEN}Sharing local folder to $VM Vbox${NC}"
  "$DOCKER_MACHINE" stop $VM
  "$VBOXMANAGE" sharedfolder add $VM -name workspace -hostpath "$(echo $PWD | sed -e 's# #\\ #g')" --automount
  "$DOCKER_MACHINE" start $VM
  echo -e "${GREEN}Mounting shared local folder on $VM Vbox boot${NC}"
  "$DOCKER_MACHINE" ssh $VM 'echo sudo mkdir /app -p | sudo tee /mnt/sda1/var/lib/boot2docker/bootlocal.sh'
  "$DOCKER_MACHINE" ssh $VM 'echo sudo mount -t vboxsf -o defaults,uid=`id -u docker`,gid=`id -g docker` workspace /app | sudo tee -a /mnt/sda1/var/lib/boot2docker/bootlocal.sh'
  echo -e "${GREEN}Restarting $VM Vbox${NC}"
  "$DOCKER_MACHINE" restart $VM
fi

STEP="Checking status on $VM"
VM_STATUS=`"$DOCKER_MACHINE" status $VM`

echo -e "${GREEN}Status of $VM:${NC} $VM_STATUS"
if [ "$VM_STATUS" != "Running" ]; then
  echo -e "${GREEN}Starting $VM Vbox${NC}"
  "$DOCKER_MACHINE" start $VM
  #"$DOCKER_MACHINE" regenerate-certs $VM
fi

STEP="Finalize"
clear
cat << EOF


                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

EOF
if [ -n "${PATH##*$DOCKER_TOOLBOX_INSTALL_PATH*}" ]; then
  echo -e "${RED}!!WARNING!! docker toolbox isn't set in your PATH${NC}"
  echo -e "Add ${GREEN}%DOCKER_TOOLBOX_INSTALL_PATH%${NC} to your the Windows environment variable ${WHITE}PATH${NC} or execute"
  echo -e "> ${BLUE}export PATH=\"\$PATH:$DOCKER_TOOLBOX_INSTALL_PATH\"${NC}"
  echo -e "in your shell to be able to use ${WHITE}docker-machine${NC} and ${WHITE}docker-compose${NC}"
fi

echo -e "${WHITE}docker${NC} is configured to use the ${GREEN}${VM}${NC} machine with IP ${GREEN}`"$DOCKER_MACHINE" ip $VM`${NC}"
echo -e "To use ${WHITE}docker${NC} set your environment by running:"
echo -e "> ${BLUE}eval \$(docker-machine env --shell=bash $VM)${NC}"


