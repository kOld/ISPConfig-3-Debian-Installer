#!/bin/bash

###############################################################################################
# Complete ISPConfig setup script for Debian/Ubuntu Systems         						  #
# Drew Clardy												                                  # 
# http://drewclardy.com				                                                          #
# http://github.com/dclardy64/ISPConfig-3-Debian-Install                                      #
###############################################################################################

cat > /root/.bashrc <<EOF
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTFILESIZE=99999999
HISTSIZE=99999999

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]'
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
#if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#    . /etc/bash_completion
#fi
alias clbin="curl -F 'clbin=<-' https://clbin.com"
alias mt="tail -f /var/log/mail.log"
alias st="tail -f /var/log/syslog"

EOF

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

if [ ! -f /usr/local/ispconfig/interface/lib/config.inc.php ]; then
    ISPConfig_Installed=No
elif [ -f /usr/local/ispconfig/interface/lib/config.inc.php ]; then
	ISPConfig_Installed=Yes
fi

# Load Variables
source config.sh

###############
## Libraries ##
###############

# Load Libraries
for file in $LIBRARYPATH/*.sh; do
	# Source Libraries
	source $file
done

# Check Distribution
if [ $DISTRIBUTION = "none" ]; then
	# Error Message
	error "Your distribution is unsupported! If you are sure that your distribution is supported please install the lsb-release package as it will improve detection."
	# Exit If Not Supported
	exit
fi

# Load Libraries (Distribution Specific)
for file in $LIBRARYPATH/platforms/*.$DISTRIBUTION.sh; do
	# Source Scripts
	source $file
done

# Load Functions (Distribution Specific)
if [ $DISTRIBUTION == "debian" ]; then
	source $FUNCTIONPATH/$DISTRIBUTION.functions.sh
elif [ $DISTRIBUTION == "ubuntu" ]; then
	source $FUNCTIONPATH/$DISTRIBUTION.functions.sh
fi

# Load Generic Functions
source $FUNCTIONPATH/generic.functions.sh

# Load Extras
for file in $EXTRAPATH/*.install.sh; do
	source $file
done


#Execute functions#
if [ $ISPConfig_Installed = "No" ]; then
	install_Questions
	$DISTRIBUTION.install_Repos
	header "Installing Basics..."
	install_Basic
	if [ $DISTRIBUTION == "ubuntu" ]; then
		ubuntu.install_DisableAppArmor
	fi
	header "Installing Database Selection..."
	if [ $sql_server == "MySQL" ]; then
		$DISTRIBUTION.install_MySQL
	fi
	if [ $sql_server == "MariaDB" ]; then
		$DISTRIBUTION.install_MariaDB
	fi
	header "Installing Mail Server Selection..."
	if [ $install_mail_server == "Yes" ]; then
		if [ $mail_server == "Courier" ]; then
			$DISTRIBUTION.install_Courier
		elif [ $mail_server == "Dovecot" ]; then
			$DISTRIBUTION.install_Dovecot
		fi
		$DISTRIBUTION.install_Virus
	fi
	header "Installing Web Server Selection..."
	if [ $install_web_server == "Yes" ]; then
		if [ $web_server == "Apache" ]; then
			$DISTRIBUTION.install_Apache
		elif [ $web_server == "NginX" ]; then
			$DISTRIBUTION.install_NginX
		fi
		$DISTRIBUTION.install_Stats
	fi
	if [ $mailman == "Yes" ]; then
		header "Installing Mailman..."
		$DISTRIBUTION.install_Mailman
	fi
	if [ $install_ftp_server == "Yes" ]; then
		header "Installing FTP Server..."
		$DISTRIBUTION.install_PureFTPD
	fi
	if [ $install_dns_server == "Yes" ]; then
		header "Installing DNS Server..."
		$DISTRIBUTION.install_Bind
	fi
	if [ $quota == "Yes" ]; then
		header "Installing Quota..."
		$DISTRIBUTION.install_Quota
	fi
	if [ $jailkit == "Yes" ]; then
		header "Installing Jailkit..."
		$DISTRIBUTION.install_Jailkit
	fi
	header "Installing Fail2Ban..."
	$DISTRIBUTION.install_Fail2Ban
	if [ $mail_server == "Courier" ]; then
		$DISTRIBUTION.install_Fail2BanRulesCourier
	fi
	if [ $mail_server == "Dovecot" ]; then
		$DISTRIBUTION.install_Fail2BanRulesDovecot
	fi
	header "Installing SquirrelMail..."
	$DISTRIBUTION.install_SquirrelMail
	header "Installing ISPConfig3..."
	install_ISPConfig
elif [ $ISPConfig_Installed == "Yes" ]; then
	warning "ISPConfig 3 already installed! Asking about extra installation scripts."
	install_Extras
	if [ $extras == "Yes" ]; then
		if [ $extra_stuff == "Themes" ]; then
			theme_questions
			if [ $theme == "ISPC-Clean" ]; then
				function_install_ISPC_Clean
			fi
		elif [ $extra_stuff == "RoundCube" ]; then
			roundcube_questions
			if [ $web_server == "Apache" ]; then
				RoundCube_install_Apache
			elif [ $web_server == "NginX" ]; then
				RoundCube_install_NginX
			fi
		fi
	fi
fi
