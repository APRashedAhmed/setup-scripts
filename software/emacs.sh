#!/bin/bash

# Script to install emacs
# Installs everything as expected if sudo is provided, or locally from source if
# it isn't

# Version to install for local emacs. Bump as needed
emacs_version=26.3

# This is useful to define here
local_dir=$HOME/.local

# Set a variable to track whether we are root or not. Combination of the
# following two stackoverflow posts
# https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
# https://stackoverflow.com/questions/9906041/bash-boolean-expression-and-its-value-assignment
[[ "$EUID" = 0 ]] && user_is_root=true || user_is_root=false

# Where emacs is supposed to be
if [ "$user_is_root" = true ]; then
    bin=/bin
else
    prefix=$local_dir/lib
    bin=$local_dir/bin
fi

# Check if there is already an emacs installation in the expected directory
if [[ -f $bin/emacs ]]; then
    # Lifted from the following stackoverflow post
    # https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
    while true; do
	read -p "Found an emacs file in the bin directory. Are you sure you \
want to install? [Y/n] " yn
	case $yn in
	    [Yy]* ) break;;
	    [Nn]* ) exit;;
	    * ) echo "Please answer yes or no.";;
	esac
    done    
fi

# Trivial case if sudo is provided
if [ "$user_is_root" = true ]; then
    apt install emacs

# Install locally from source
else
    # Set variables
    emacs_root=emacs-$emacs_version
    emacs_tar=$emacs_root.tar.xz
    emacs_source=https://ftp.gnu.org/pub/gnu/emacs/$emacs_tar

    # Download
    if [[ ! -f $emacs_tar ]]; then
    	dl_dir=$HOME/Downloads
	shopt -s expand_aliases
	alias wgetdl="wget -P $dl_dir" 	# Send wget files to dl_dir
	wgetdl $emacs_source -O $emacs_tar
    fi

    # Unzip the .xz if it doesnt exist and cd there
    if [[ ! -d $emacs_root ]]; then
	# See this superuser post for the meaning of this line
	# https://superuser.com/questions/146814/unpack-tar-but-change-directory-name-to-extract-to
	mkdir -p $emacs_root
	tar -xf $emacs_tar -C $emacs_root --strip-components=1
    fi
    cd $emacs_root

    # Autogen
    ./autogen.sh
    # Configure to the requirements of the machine
    ./configure \
    	--prefix=$prefix/emacs \
    	--bindir=$bin \
    	--with-xpm=no \
	--with-png=no \
	--with-gif=no \
	--with-gnutls=no
    # Make things
    make && make install

    # Cleanup after outselves
    cd -
    rm -rf $emacs_root $emacs_tar
fi
