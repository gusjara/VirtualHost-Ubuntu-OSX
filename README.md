This script allows you to easily create virtual hosts for a development environment on Ubuntu under Apache server. This way you can reflect a production environment locally.
Based upon:
- [virtualhost.sh](https://raw.github.com/pgib/virtualhost.sh/master/virtualhost.sh) script for OS X by [Patrick Gibson](https://github.com/pgib) (basicly copied-pasted)
- [virtualhost.sh](https://raw.github.com/pgib/virtualhost.sh/ubuntu/virtualhost.sh) script for Ubuntu by [Bjorn Wijers](https://github.com/BjornW)

All credits to them.

## Download
You can grab the [script here](https://raw.github.com/miguelzilli/virtualhost.sh/master/virtualhost.sh) (ctrl+click to download). You'll need to run `chmod +x virtualhost.sh` in order to run it after downloading.

## Usage
	sudo sh virtualhost.sh [--add|--delete] <name> [-y]
	sudo sh virtualhost.sh [OPTION]
Where `<name>` is the one-word name you would like to use. (e.g. mysite). If `-y` option is given all prompting will assume the default answer.

Options:	
  -l  --list     Lists all virtual hosts located in VIRTUAL_HOSTS_ENABLED	
  -c  --config   Prints the current config of the script	
  -h  --help     Prints this help	
  -v  --version  Prints version number		

Note that if "virtualhost.sh" is not in your PATH, you will have to write out the full path to it: eg. /home/[you]/downloads/virtualhost.sh

##Documentation
soon...
