#!/bin/bash

# Script to install zsh and make it the default shell
# If root is available, zsh is installed as root, zsh is added to the list of
# avaiable shells, and the default shell for the user is changed. If root is not
# available, then zsh is set to run at the end of the local bash script. The
# latter approach is lifted from this page:
# https://franklingu.github.io/programming/2016/05/24/setup-oh-my-zsh-on-ubuntu-without-sudo/

# Version to install. Bump as needed
zsh_version=5.7.1

# This is useful to define here
local_dir=$HOME/.local

# Set a variable to track whether we are root or not. Combination of the
# following two stackoverflow posts
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
# https://stackoverflow.com/questions/9906041/bash-boolean-expression-and-its-value-assignment
[[ "$EUID" = 0 ]] && user_is_root=true || user_is_root=false

# Install required packages if we are root and set variables accordingly
if [ "$user_is_root" = true ]; then
    # Install requirements
    apt install \
	 build-essential \
	 libgdbm-dev \
	 libcap-dev \
	 libpcre3 \
	 libpcre3-dev \
	 libncurses5-dev \
	 libncursesw5-dev

    # Set vars
    prefix=/usr
    bin=/bin
    sysconfdir=/etc/zsh
    enable_etcdir=/etc/zsh
else
    prefix=$local_dir
    bin=$local_dir/bin
    sysconfdir=$local_dir/etc/zsh
    enable_etcdir=$local_dir/etc/zsh
fi

# Check if there is already a zsh installation in the expected directory
if [[ -f $bin/zsh ]]; then
    # Lifted from the following stackoverflow post
    # https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
    while true; do
	read -p "Found a zsh file in the bin directory. Are you sure you want \
to install? [Y/n] " yn
	case $yn in
	    [Yy]* ) break;;
	    [Nn]* ) exit;;
	    * ) echo "Please answer yes or no.";;
	esac
    done    
fi

# Set some variables
zsh_root=zsh-$zsh_version
zsh_tar=$zsh_root.tar.xz
zsh_source=https://sourceforge.net/projects/zsh/files/zsh/$zsh_version/$zsh_tar/download

# Download if it doesn't exist
if [[ ! -f $zsh_tar ]]; then
    wget $zsh_source -O $zsh_tar
fi

# Unzip the .xz if it doesnt exist
if [[ ! -d $zsh_root ]]; then
    # See this superuser post for the meaning of this line
    # https://superuser.com/questions/146814/unpack-tar-but-change-directory-name-to-extract-to
    mkdir -p $zsh_root; tar -xf $zsh_tar -C $zsh_root --strip-components=1
fi
cd $zsh_root

# Configure and make according to linux-from-scratch
# http://www.linuxfromscratch.org/blfs/view/svn/postlfs/zsh.html
./configure --prefix=$prefix \
            --bindir=$bin\
            --sysconfdir=$etc \
            --enable-etcdir=$etc
make

# Now check that everything went okay
make check
# This should run a battery of tests which will hopefully return something like this at the end
# **************************************
# 50 successful test scripts, 0 failures, 1 skipped
# **************************************

# Install things globally if we have sudo
if [ "$user_is_root" = true ]; then
    # Run the following commands as root. See the stackoverflow post
    # https://unix.stackexchange.com/questions/1087/su-options-running-command-as-another-user
    # Install zsh as root
    su -c "make install" root
    
    # Add zsh to the list of shells
    su -c "command -v zsh | sudo tee -a /etc/shells" root
    
    # Get the non sudo username. See this stackoverflow post
    # https://stackoverflow.com/questions/4598001/how-do-you-find-the-original-user-through-multiple-sudo-and-su-commands
    user=`logname`
    # Set the default shell for the user
    su -u "chsh -s /bin/zsh $user" root
    
    # Historically, things need to restart to take effect
    printf "Changed the default shell to zsh for $user. You may need to \
restart your computer for it to take effect."

else
    # Install locally if we dont have sudo
    make install

    # Check if the exec zsh line is in bashrc
    if ! grep -q "exec zsh" $local_dir/.bashrc; then
	# Exec zsh upon entering bash
	printf "\nexec zsh\n" >> $local_dir/.bashrc
    fi
fi

# Cleanup after ourselves
cd -
rm -rf $zsh_root $zsh_tar
