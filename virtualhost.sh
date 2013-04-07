#!/bin/sh
###############################################################################
# virtualhost.sh
###############################################################################
# A fancy little script to setup a new virtual host in Ubuntu.
# Based upon : 
# - virtualhost script for OS X by Patrick Gibson <patrick@patrickg.com>
# - virtualhost script for Ubuntu by Bjorn Wijers <burobjorn@burobjorn.nl>
# All credits to them.
#
# Modified by Miguel Zilli
###############################################################################
# WHAT'S NEW
###############################################################################
# Version: 13.04
# - The same as in v1.30 of virtualhost for OS X, except for the automatic
#   updates, the DocRoot and apache2.conf checks.
# + Now you can create a new virtual host in XAMPP for Linux (*).
# + Change the usage of the script. Added an  '--add' option.
# + Added --config (-c): prints the current settings
# + Added --help (-h): prints more detailed help and usage (useless)
# + Added --version (-v): prints the current version (useless)
# + Added '-y' option to enter in batch mode.
# - Modified index.html. Now it has nice HTML5 and CSS3 (useless)
# + Coded exit codes:
#     0 -> all Ok
#     1 -> runing without super-user privileges or root using sudo
#     2 -> bad option(s) -> print usage
#     3 -> invalid host name
#     4 -> virtual host does not exist
# 
# (*) At the moment there's a problem/bug with the new "Security Concept" of 
# XAMPP. See this: www.apachefriends.org/f/viewtopic.php?f=17&t=50902
###############################################################################
# USAGE: 
#       sudo sh virtualhost.sh [--add|--delete] name
# Where <name> is the one-word name you would like to use. (e.g. mysite)
# Try 'virtualhost.sh --help' for more information
###############################################################################

###############################################################################
# SETTINGS
###############################################################################

# If you are using this script on a production machine with a static IP address
# and you wish to setup a "live" virtualhost, you can change the following IP
# address to the IP address of your machine.
IP_ADDRESS="127.0.0.1"

# If Apache works on a different port than the default 80, set it here
APACHE_PORT="80"

# By default, this script places files in /home/[you]/www. If you would like to
# change this, like to how Apache on Ubuntu does things by default, uncomment 
# the following line:
#DOC_ROOT_PREFIX="/var/www"

# Configure the apache-related paths if these defaults do not work for you.
APACHE_RESTART_COMMAND="/usr/sbin/apache2ctl graceful"

# Set the virtual host configuration files directories
VIRTUAL_HOSTS_ENABLED="/etc/apache2/sites-enabled"
VIRTUAL_HOSTS_AVAILABLE="/etc/apache2/sites-available"

# By default, log files will be created in DOCUMENT_ROOT/logs. If you wish to
# override this to a static location, you can do so here.
LOG_FOLDER="/var/log/apache2"

###############################################################################
# XAMPP SETTINGS
###############################################################################
#XAMPP_FOR_LINUX="yes"
#APACHE_HTTPD_CONF="/opt/lampp/etc/httpd.conf"
#DOC_ROOT_PREFIX="/opt/lampp/htdocs"
#APACHE_RESTART_COMMAND="/opt/lampp/lampp restart"
#VIRTUAL_HOSTS_ENABLED="/opt/lampp/etc/extra"
#VIRTUAL_HOSTS_AVAILABLE="/opt/lampp/etc/extra"
#LOG_FOLDER="/opt/lampp/logs"

###############################################################################
# SCRIPT BEHAIVIOR AND EXTRAS
###############################################################################

# If defined, a ServerAlias os $1.$WILDCARD_ZONE will be added to the virtual
# host file. This is useful if you, for example, have setup a wildcard domain
# either on your own DNS server or using a server like dyndns.org. For example,
# if my local IP of 10.0.42.42 is static (which can still be achieved using a
# well-configured DHCP server or an Apple Airport Extreme 802.11n base station)
# and I create a host on dyndns.org of patrickdev.dyndns.org with wildcard
# hostnames turned on, then defining my WILDCARD_ZONE to "patrickdev.dyndns.org"
# will enable access to my virtual host from any machine on the network. Note
# that this would also work with a public IP too, and the virtual hosts on your
# machine would be accessible to anyone on the internets.
#WILDCARD_ZONE="my.wildcard.host.address"

# Batch mode (all prompting will assume the default value). Any value will 
# activate this.
# If you never want to be prompted, uncomment this line. Or you can use the
# "-y" option in command line (e.g. `sh virtualhost.sh --add mysite -y`)
#BATCH_MODE="yes"

# A feature to specify a custom log location within your site's document root
# was requested, and so you will be prompted about this when you create a new
# virtual host. If you do not want to be prompted, set the following to "no":
PROMPT_FOR_LOGS="no"

# If you do not want to be prompted, but you do always want to have the site-
# specific logs folder, set PROMPT_FOR_LOGS="no" and enable this:
ALWAYS_CREATE_LOGS="yes"

# If you have an atypical setup, and you don't need or want entries in your
# /etc/hosts file, you can set the following option to "yes".
SKIP_ETC_HOSTS="no"

# By default, the site folder that get created will be owned by this group
OWNER_GROUP="www-data"

# If you don't want to create an example index.html in your virtual host folder
# uncomment the following line:
#SKIP_INDEX_CREATION="yes"

# Set to "yes" if you don't want the site to be launched in your browser after
# the virtual host is setup
#SKIP_BROWSER="yes"

# Set the browser to use. In Ubuntu you can use xdg-open to use the system 
# default browser, but you can use your own browser.
OPEN_COMMAND="/usr/bin/xdg-open"
#OPEN_COMMAND="/usr/bin/firefox -new-tab"

# You can now store your configuration directions in a ~/.virtualhost.sh.conf
# file so that you can download new versions of the script without having to
# redo your own settings.
if [ -e ~/.virtualhost.sh.conf ]; then
  . ~/.virtualhost.sh.conf
fi
#======= DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING =======
VERSION="13.04"

# No point going any farther if we're not running correctly...
if [ `whoami` != 'root' ]; then
  echo "virtualhost.sh requires super-user privileges to work."
  echo "Enter your password to continue..."
  sudo $0 $* || exit 1
  exit 0
fi

if [ "$SUDO_USER" = "root" ]; then
  /bin/echo "You must start this under your regular user account (not root) using sudo."
  /bin/echo "Rerun using: sudo $0 $*"
  exit 1
fi

#================================= FUNCTIONS =================================
host_exists()
{
  if grep -q -e "^$IP_ADDRESS  $1$" /etc/hosts ; then
    return 0
  else
    return 1
  fi
}

# usage: create_virtualhost name docroot [logs_folder]
create_virtualhost()
{
  if [ ! -z $WILDCARD_ZONE ]; then
    SERVER_ALIAS="ServerAlias $1.$WILDCARD_ZONE"
  else
    SERVER_ALIAS="#ServerAlias your.alias.here"
  fi
  date=`/bin/date`
  if [ -z $3 ]; then
    log="#"
  else
    log=""
    if [ ! -z $LOG_FOLDER ]; then
      log_folder_path=$LOG_FOLDER
      access_log="${log_folder_path}/$1-access_log"
      error_log="${log_folder_path}/$1-error_log"
    else
      log_folder_path=$FOLDER/logs
      access_log="${log_folder_path}/access_log"
      error_log="${log_folder_path}/error_log"
    fi
    if [ ! -d "${log_folder_path}" ]; then
      mkdir -p "${log_folder_path}"
      chown $USER:$OWNER_GROUP "${log_folder_path}"
    fi
    touch $access_log $error_log
    chown $USER:$OWNER_GROUP $access_log $error_log
  fi
  cat << __EOF >$VIRTUAL_HOSTS_AVAILABLE/$1
# Virtual Host: $1
# Created: $date
<VirtualHost *:$APACHE_PORT>
  DocumentRoot "$2"
  ServerName $1
  $SERVER_ALIAS

  <Directory "$2">
    Options All
    AllowOverride All
    #Order allow,deny
    #Allow from all
  </Directory>

  ${log}CustomLog "${access_log}" combined
  ${log}ErrorLog "${error_log}"
</VirtualHost>
__EOF
}

list_virtualhosts()
{
  if [ -d $VIRTUAL_HOSTS_ENABLED ]; then
    echo "Listing virtualhosts found in $VIRTUAL_HOSTS_ENABLED"
    echo
    for i in $VIRTUAL_HOSTS_ENABLED/*; do
      if ! echo "$i" | grep -q 'ht.*.conf$' ; then
        server_name=`grep ServerName $i | awk '{print $2}'`
        doc_root=`grep DocumentRoot $i | awk '{print $2}' | sed -e 's/"//g'`
        echo "http://${server_name}/ -> ${doc_root}"
      fi
    done
  else
    echo "No virtualhosts have been setup yet."
  fi
  exit
}

restart_apache()
{
  /bin/echo -n " *Restarting Apache... "
  $APACHE_RESTART_COMMAND 1>/dev/null 2>/dev/null
  /bin/echo "Done"
}

# Based on FreeBSD's /etc/rc.subr
checkyesno()
{
  case $1 in
    [Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|[Yy]|1) # "yes", "true", "on", or "1"
    return 0
    ;;
    [Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|[Nn]|0) # "no", "false", "off", or "0"
    return 1
    ;;
    *)
    return 1
    ;;
  esac
}

usage()
{
  cat << __EOT
Usage: sudo sh virtualhost.sh [--add|--delete] name
Where <name> is the one-word name you would like to use. (e.g. mysite)
Try 'virtualhost.sh --help' for more information
__EOT
exit 2
}

print_help()
{
  cat << __EOT
Usage: sudo sh virtualhost.sh [--add|--delete] <name> [-y]
       sudo sh virtualhost.sh [OPTION]
Where <name> is the one-word name you would like to use. (e.g. mysite)
If '-y' option is given all prompting will assume the default answer.

Options:
  -l  --list     Lists all virtual hosts located in VIRTUAL_HOSTS_ENABLED
  -c  --config   Prints the current config of the script
  -h  --help     Prints this help
  -v  --version  Prints version number

Note that if "virtualhost.sh" is not in your PATH, you will have to write out 
the full path to it: eg. /home/$USER/downloads/virtualhost.sh
__EOT
  exit
}

print_config()
{
  if [ -z $DOC_ROOT_PREFIX ]; then
    DOC_ROOT_PREFIX2="/home/[you]/www"
  else
    if [ -d $DOC_ROOT_PREFIX ]; then
      DOC_ROOT_PREFIX2=$DOC_ROOT_PREFIX
    else
      DOC_ROOT_PREFIX2="WARNING: $DOC_ROOT_PREFIX not found."
    fi
  fi

  if [ -z $LOG_FOLDER ]; then
    LOG_FOLDER2=$DOC_ROOT_PREFIX2/[your-site]/logs
  else
    LOG_FOLDER2=$LOG_FOLDER
  fi

  if [ -z $XAMPP_FOR_LINUX ]; then
    XAMPP_FOR_LINUX2="Turned off. Not using XAMPP for Linux."
    APACHE_HTTPD_CONF2="No needed."
  else
    XAMPP_FOR_LINUX2="Using XAMPP for Linux."
    if [ -z $APACHE_HTTPD_CONF ]; then
      APACHE_HTTPD_CONF2="ERROR: you need to indicate the path to httpd.conf file"
    else
      if [ -e $APACHE_HTTPD_CONF ]; then
        APACHE_HTTPD_CONF2=$APACHE_HTTPD_CONF
      else
        APACHE_HTTPD_CONF2="ERROR: File not found: $APACHE_HTTPD_CONF"
      fi
    fi
  fi

  if [ -z $SKIP_INDEX_CREATION ]; then
    SKIP_INDEX_CREATION2="no"
  else
    SKIP_INDEX_CREATION2="yes"
  fi

  if [ -z $SKIP_BROWSER ]; then
    SKIP_BROWSER2="No"
    if [ -z "$OPEN_COMMAND" ]; then
      OPEN_COMMAND2="ERROR: you need to specify an OPEN_COMMAND"
    else
      OPEN_COMMAND2=$OPEN_COMMAND
    fi
  else
    SKIP_BROWSER2="yes"
    OPEN_COMMAND2="No needed"
  fi

cat << __EOT
virtualhost.sh current config:
IP_ADDRESS:              $IP_ADDRESS
APACHE_PORT:             $APACHE_PORT
XAMPP_FOR_LINUX:         $XAMPP_FOR_LINUX2
APACHE_HTTPD_CONF:       $APACHE_HTTPD_CONF2
DOC_ROOT_PREFIX:         $DOC_ROOT_PREFIX2
APACHE_RESTART_COMMAND:  $APACHE_RESTART_COMMAND
VIRTUAL_HOSTS_ENABLED:   $VIRTUAL_HOSTS_ENABLED
VIRTUAL_HOSTS_AVAILABLE: $VIRTUAL_HOSTS_AVAILABLE
LOG_FOLDER:              $LOG_FOLDER2
PROMPT_FOR_LOGS:         $PROMPT_FOR_LOGS
ALWAYS_CREATE_LOGS:      $ALWAYS_CREATE_LOGS
SKIP_ETC_HOSTS:          $SKIP_ETC_HOSTS
OWNER_GROUP:             $OWNER_GROUP
SKIP_INDEX_CREATION:     $SKIP_INDEX_CREATION2
SKIP_BROWSER:            $SKIP_BROWSER2
OPEN_COMMAND:            $OPEN_COMMAND2

__EOT
exit
}
#============================ END FUNCTIONS SECTION ===========================

# Ask for username (if no definded yet)
if [ -z $USER -o $USER = "root" ]; then
  if [ ! -z $SUDO_USER ]; then
    USER=$SUDO_USER
  else
    USER=""
    /bin/echo "ALERT! Your root shell did not provide your username."
    while : ; do
      if [ -z $USER ]; then
        while : ; do
          /bin/echo -n "Please enter *your* username: "
          read USER
          if [ -d /home/$USER ]; then
            break
          else
            /bin/echo "$USER is not a valid username."
          fi
        done
      else
        break
      fi
    done
  fi
fi

# Set the DOC_ROOT_PREFIX if not defined yet
if [ -z $DOC_ROOT_PREFIX ]; then
  DOC_ROOT_PREFIX="/home/$USER/www"
fi

# See what we have to do
case "$1" in
  --add)
    if [ -z $2 ]; then
      usage
    else
      VIRTUALHOST=$2
    fi
  ;;
  --delete)
    if [ -z $2 ]; then
      usage
    else
      VIRTUALHOST=$2
      DELETE=0
    fi
  ;;
  --list|-l)
    list_virtualhosts
  ;;
  --config|-c)
    print_config
  ;;
  --help|-h)
    print_help
  ;;
  --version|-v)
    echo virtualhost.sh version: "$VERSION"
    exit
  ;;
  *)
    usage
  ;;
esac

# Test that the virtualhost name is valid (starts with a number or letter)
if ! /bin/echo $VIRTUALHOST | grep -q -E '^[A-Za-z0-9]+' ; then
  /bin/echo "Sorry, '$VIRTUALHOST' is not a valid host name. It must start with a letter or number."
  exit 3
fi

if [ "$3" = '-y' ]; then
  BATCH_MODE='yes'
fi
################################################################################
# Delete virtualhost
################################################################################
if [ ! -z $DELETE ]; then
  /bin/echo -n "Are you sure you want to delete: $VIRTUALHOST ? [Y/n]: "
  if [ -z "$BATCH_MODE" ]; then
    read continue
  else
    continue="Y"
    /bin/echo $continue
  fi
  case $continue in
  n*|N*) exit
  esac

  # Delete entry from /etc/hosts
  if ! checkyesno ${SKIP_ETC_HOSTS}; then
    /bin/echo -n " *Removing $VIRTUALHOST from /etc/hosts... "
    cat /etc/hosts | grep -v $VIRTUALHOST > /tmp/hosts.tmp
    if [ -s /tmp/hosts.tmp ]; then
      mv /tmp/hosts.tmp /etc/hosts
    fi
    /bin/echo "Done"
  fi

  if [ -e $VIRTUAL_HOSTS_AVAILABLE/$VIRTUALHOST ]; then
    # Delete DocumentRoot folder
    DOCUMENT_ROOT=`grep DocumentRoot $VIRTUAL_HOSTS_AVAILABLE/$VIRTUALHOST | awk '{print $2}' | tr -d '"'`
    if [ -d $DOCUMENT_ROOT ]; then
      /bin/echo -n "Found DocumentRoot $DOCUMENT_ROOT. Delete this folder? [y/N]: "
      if [ -z $BATCH_MODE ]; then
        read resp
      else
        resp="N"
        echo $resp
      fi
      case $resp in
      y*|Y*)
        /bin/echo -n " *Deleting DocumentRoot folder... "
        if rm -rf "${DOCUMENT_ROOT}" ; then
          /bin/echo "Done"
        else
          /bin/echo "Could not delete $DOCUMENT_ROOT"
        fi
      ;;
      esac
    fi

    # Delete log files
    LOG_FILES=`grep "CustomLog\|ErrorLog" $VIRTUAL_HOSTS_AVAILABLE/$VIRTUALHOST | awk '{print $2}' | tr -d '"'`
    if [ ! -z "$LOG_FILES" ]; then
      /bin/echo -n "Delete log files? [Y/n]: "
      if [ -z BATCH_MODE ]; then
        read resp
      else
        resp="Y"
        echo $resp
      fi
      case $resp in
      y*|Y*)
        for i in $LOG_FILES; do
          /bin/echo -n " *Deleting $i... "
          if rm -f $i ; then
            /bin/echo "Done"
          else
            /bin/echo "Could not delete $i"
          fi
        done
      ;;
      esac
    fi

    #Delete virtualhost file
    /bin/echo -n " *Deleting virtualhost file: $VIRTUAL_HOSTS_AVAILABLE/$VIRTUALHOST... "
    if [ -z $XAMPP_FOR_LINUX ]; then
      /usr/sbin/a2dissite $VIRTUALHOST 1>/dev/null 2>/dev/null
    else
      cat $APACHE_HTTPD_CONF | grep -v $VIRTUALHOST > /tmp/httpd_conf.tmp
      if [ -s /tmp/httpd_conf.tmp ]; then
        mv /tmp/httpd_conf.tmp $APACHE_HTTPD_CONF
      fi
    fi
    rm $VIRTUAL_HOSTS_AVAILABLE/$VIRTUALHOST
    /bin/echo "Done"

    restart_apache
    /bin/echo "Virtual host $VIRTUALHOST deleted successfuly"
  else
    /bin/echo "Virtual host $VIRTUALHOST does not exist. Aborting..."
    exit 4
  fi
  exit
fi

################################################################################
# Add new virtual host
################################################################################
FIRSTNAME=`pinky | awk '{print $2}' | tail -n 1`
cat << __EOT
Hi $FIRSTNAME! Welcome to virtualhost.sh. This script will guide you through setting up a new name-based virtual host.
__EOT
echo -n "Do you wish to continue? [Y/n]: "
if [ -z BATCH_MODE ]; then
  read continue
else
  resp="Y"
  echo $continue
fi
case $continue in
n*|N*) exit
esac

# If the host is not already defined in /etc/hosts, define it...
if ! checkyesno ${SKIP_ETC_HOSTS}; then
  if ! host_exists $VIRTUALHOST ; then
    /bin/echo -n " *Adding $VIRTUALHOST to /etc/hosts... "
    /bin/echo "$IP_ADDRESS  $VIRTUALHOST" >> /etc/hosts
    /bin/echo "Done"
  fi
fi

# Ask the user where they would like to put the files for this virtual host
/bin/echo -n " *Looking in $DOC_ROOT_PREFIX for an existing document root to use... "

# See if we can find an appropriate folder
if ls -1 $DOC_ROOT_PREFIX | grep -q -e "^$VIRTUALHOST"; then
  DOC_ROOT_FOLDER_MATCH=`ls -1 $DOC_ROOT_PREFIX | grep -e ^$VIRTUALHOST | head -n 1`
  DOC_ROOT_FOLDER_MATCH="${DOC_ROOT_PREFIX}/${DOC_ROOT_FOLDER_MATCH}"
  /bin/echo "Found"
else
  if [ -d $DOC_ROOT_PREFIX/$VIRTUALHOST ]; then
    DOC_ROOT_FOLDER_MATCH="$DOC_ROOT_PREFIX/$VIRTUALHOST"
    /bin/echo "Found"
  else
    nested_match=`find $DOC_ROOT_PREFIX -maxdepth 2 -type d -name $VIRTUALHOST 2>/dev/null`
    if [ -n "$nested_match" ]; then
      if [ -d $nested_match ]; then
        DOC_ROOT_FOLDER_MATCH=$nested_match
        /bin/echo "Found"
      fi
    else
      DOC_ROOT_FOLDER_MATCH="$DOC_ROOT_PREFIX/$VIRTUALHOST"
      /bin/echo "Nothing found"
    fi
  fi
fi

/bin/echo -n "Use $DOC_ROOT_FOLDER_MATCH as the virtual host folder? [Y/n]: "
if [ -z "$BATCH_MODE" ]; then
  read resp
else
  resp="Y"
  echo $resp
fi
case $resp in
  n*|N*)
    while : ; do
      if [ -z "$FOLDER" ]; then
        /bin/echo -n "Enter new folder name (located in $DOC_ROOT_PREFIX): "
        read FOLDER
      else
        break
      fi
    done
  ;;
  *)
    FOLDER=$DOC_ROOT_FOLDER_MATCH
    if [ -d $DOC_ROOT_FOLDER_MATCH/public ]; then
      /bin/echo -n "Found a public folder suggesting a Rails/Merb/Rack project. Use as DocumentRoot? [y/N]: "
      if [ -z "$BATCH_MODE" ]; then
        read response
      else
        response="N"
        /bin/echo $response
      fi
      if checkyesno ${response} ; then
        FOLDER=$DOC_ROOT_FOLDER_MATCH/public
      fi
    elif [ -d $DOC_ROOT_FOLDER_MATCH/web ]; then
      /bin/echo -n "Found a web folder suggesting a Symfony project. Use as DocumentRoot? [Y/n]: "
      if [ -z "$BATCH_MODE" ]; then
        read response
      else
        response="Y"
        /bin/echo $response
      fi
      if checkyesno ${response} ; then
        FOLDER=$DOC_ROOT_FOLDER_MATCH/web
      fi
    fi
  ;;
esac

# Create the folder if we need to...
if [ ! -d "${FOLDER}" ]; then
  /bin/echo -n " *Creating folder ${FOLDER}... "
  su $USER -c "mkdir -p $FOLDER"
  /bin/echo "Done"
fi

# See if a custom log should be used
if checkyesno ${PROMPT_FOR_LOGS}; then
  /bin/echo -n "Enable custom server access and error logs in $VIRTUALHOST/logs? [y/N]: "
  if [ -z "$BATCH_MODE" ]; then
    read resp
  else
    resp="Y"
    echo $resp
  fi
  case $resp in
    y*|Y*)
      log="1"
    ;;
    *)
      log=""
    ;;
  esac
elif checkyesno ${ALWAYS_CREATE_LOGS}; then
  log="1"
fi

# Create a default index.html
if [ -z $SKIP_INDEX_CREATION ]; then
  if [ ! -e "${FOLDER}/index.html" -a ! -e "${FOLDER}/index.php" ]; then
    cat << __EOF >"${FOLDER}/index.html"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"> 
  <title>Welcome to $VIRTUALHOST</title>
  <style type="text/css">
  body {color:#555; font-family:Arial, Helvetica, Sans-Serif;}
  #box {background:#F4F4F4; background:-moz-linear-gradient(top, #EEEEEE, #BBBBBB); background:-webkit-gradient(linear, 0% 0%, 0% 100%, from(#EEEEEE), to(#BBBBBB)); border:1px solid #aaa; border-radius:20px; -moz-border-radius:20px; -webkit-border-radius:20px; box-shadow:5px 5px 20px #000000; -moz-box-shadow:5px 5px 20px #000000; -webkit-box-shadow:5px 5px 20px #000000; width:45%; padding:0 10px 10px 10px; margin:5em auto;}
  header {text-align:center;}
  h1 {color:#114477; text-shadow: 0px 1px 0px #999, 0px 2px 0px #888, 0px 3px 0px #777, 0px 4px 0px #666, 0px 5px 0px #555, 0px 6px 0px #444, 0px 7px 0px #333, 0px 8px 7px #013;}
  a {color:#993300; text-decoration: none;}
  a:hover {text-shadow: 0px 0px 2px #440707;}
  b { color:#333; }
  </style>
</head>
<body>
  <div id="box">
   <header>
    <h1>Congratulations!</h1>
  </header>
    <p>If you are reading this in your web browser, then the only logical conclusion is that the <a href="http://$VIRTUALHOST:$APACHE_PORT/">http://$VIRTUALHOST:$APACHE_PORT/</a> virtualhost was setup correctly. :)</p>
    <p>You can find the configuration file for this virtual host in:<br>
      $VIRTUAL_HOSTS_AVAILABLE/$VIRTUALHOST
    </p>
    <p>You will need to place all of your website files in:<br>
      <a href="file://$FOLDER">$FOLDER</a>
    </p>
  <footer>
    <p>Modified by Miguel Zilli<br>
      For the original version of this script visit: <a href="http://patrickg.com/virtualhost">http://patrickg.com/virtualhost</a>
    </p>
  </footer>
</div>
</body>
</html>
__EOF
    chown $USER:$OWNER_GROUP "${FOLDER}/index.html"
  fi
fi

# Create the virtualhost config file
/bin/echo -n " *Creating virtual host file... "
create_virtualhost $VIRTUALHOST "${FOLDER}" $log
if [ -z $XAMPP_FOR_LINUX ]; then
  /usr/sbin/a2ensite $VIRTUALHOST 1>/dev/null 2>/dev/null
else
  /bin/echo "Include $VIRTUAL_HOSTS_AVAILABLE/$1" >> $APACHE_HTTPD_CONF
fi
/bin/echo "Done"

restart_apache

# Launch the new URL in the browser
if [ -z $SKIP_BROWSER ]; then
  /bin/echo -n " *Launching virtual host... "
  su $USER -c "$OPEN_COMMAND http://$VIRTUALHOST:$APACHE_PORT/"
 /bin/echo "Done"
fi

cat << __EOF
Virtual host http://$VIRTUALHOST:$APACHE_PORT/ is setup and ready for use.
__EOF
