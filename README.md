# docker-toolbox-env
A setup to map current project directory to docker virtualbox.

## Usage

Simply run the script form the home directory of your project.

## Context

I develop on a **Windows 10 Home** machine with **git Bash** on different king of web projects. The problem is that Docker isn't meant to be deployed on such configuration. Indeed, Windows 10 Home does not provide _Hyper-X_, thus Docker provides a toolbox which is basically a _VirtualBox_ machine with a minimal linux configuration named docker-machine.

The problem with this toolbox it that it does not map the working directory to the docker-machine, and one has to trick manually the configuration if he want to have the modifications updated live in the dockers file system.

## What does this script?

The script will check that Docker toolbox is properly installed (i.e. environment variables for virtualbox manager and docker-machine). Then it will look for a docker-machine with the name of the current folder. If none exists, it will create a new one, bind the current folder to the _Docker VirtualBox_, and mount it as "/app", and ensure that the binding remains after restarting it. Although your dev dockerfile can map the source volumes to this base folder.

## Further work

So far the script simply runs and yells the missing environement variables to be set to run the _docker-machine_ and _docker-compose_ from the git-bash prompt. It is possible to set the ~/.bashrc to have these variables set globally.

## Known issues

Beware that if you use NodeJS and NPM modules, the paths of your working directory should remain less than 260 chars. This constraint is freed as of Windows 10 build 1607, but still has to be triggered manually : http://superuser.com/questions/1119883/windows-10-enable-ntfs-long-paths-policy-option-missing
