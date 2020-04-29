#!/bin/bash

# Setting up a serrelab computer from scratch since I've had to do this several
# times. Assumes access to the internet, no sudo priviledges, and bash as the
# shell. It does the following:

# - Directory structure is the expected one
# - Modifies and adds to the path
# - Clones the dotfiles repo and installs it
# - Installs zsh locally
# - Installs emacs locally
# - Installs macgick locally



# Third party software versions. Bump as needed
zsh_version=5.7.1
emacs_version=26.3

# Start here
cd $HOME


# # Ensure The standard directory structure is present

printf "Updating directories.\n"

# Make sure basic folders are present
xdg-user-dirs-update

# Defining some directories
work_dir=$HOME/work
local_dir=$HOME/.local
bin_dir=$local_dir/bin
lib_dir=$local_dir/lib
bak_dir=$local_dir/backups

# List of dirs to ensure existance besides the xdg user dirs. Add more if needed
base_dirs=(
    $work_dir
    $local_dir
    $bin_dir
    $lib_dir
    $bak_dir
)

for dir in "${base_dirs[@]}"; do
    mkdir -p $dir
done


# # A couple useful things going forward

# Directories
dl_dir=$HOME/Downloads

# Make sure these exist
local_bashrc=$local_dir/.bashrc
local_zshrc=$local_dir/.zshrc

# Go through and create them all
base_files=(
    $local_bashrc
    $local_zshrc
)
for file in "${base_files[@]}"; do
    touch $file
done

# Fun little alias
# Learned that aliases dont work within scripts on their own. They need this
# line to work. See this page for more detail:
#https://www.thegeekdiary.com/how-to-make-alias-command-work-in-bash-script-or-bashrc-file/
shopt -s expand_aliases
alias wgetdl="wget -P $dl_dir" 	# Send wget files to dl_dir


# # Ensure path has the right stuff in it

# Make sure .local/bin dir is in the current (bash) path
if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" $local_bashrc; then
    # Not in the file, add the following lines
    printf "\n# Check if .local/bin is in the path and add if not
if [[ ':\$PATH:' != *':\$HOME/.local/bin:'* ]]; then
    export PATH=\$HOME/.local/bin:\$PATH
fi\n" >> $local_bashrc
fi


# Add this check to local_zshrc if it isn't in there
if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" $local_zshrc; then
    # Not in the file, add the following lines
    printf "\n# Check if .local/bin is in the path and add if not
if [[ ':\$PATH:' != *':\$HOME/.local/bin:'* ]]; then
    export PATH=\$HOME/.local/bin:\$PATH
fi\n" >> $local_zshrc
fi

# Serre lab machine specific additions
if ! grep -q "source \$DOTPATH/groups/serre.sh" $local_bashrc; then
    # Not in the file, add the following lines
    printf "\n# Source some things specific to serre-lab machines
DOTPATH=\$HOME/.dotfiles
source \$DOTPATH/groups/serre.sh\n" >> $local_bashrc
fi
# Add this to the zsh local
if ! grep -q "source \$DOTPATH/groups/serre.sh" $local_zshrc; then
    # Not in the file, add the following lines
    printf "\n# Source some things specific to serre-lab machines
DOTPATH=\$HOME/.dotfiles
source \$DOTPATH/groups/serre.sh\n" >> $local_zshrc
fi


# # Miscellaneous

# Move this repo to work if its in the home directory
if [[ -d $HOME/db7191d0720df8a0abf49e5af1125bf7 ]]; then
    mv $HOME/db7191d0720df8a0abf49e5af1125bf7 $work_dir/setup_serre_gist
fi

# Make sure we have a soft link to the right data_cifs dir
ln -sfn /media/data_cifs/apra $HOME/data_cifs


# # Dotfiles

dot_dir=$work_dir/dotfiles

# If the directory doesn't exist, run the setup
if [ ! -d $dot_dir ]; then
    printf "\nNo dot files repo found, cloning and installing.\n"
    # Clone it if it doesn't exist
    git clone https://github.com/apra93/dotfiles.git $dot_dir

    # Do some cleanup first
    # Create an array of relevant files. Add to this as needed
    dot_list=(
	.bashrc
	.bash_history
	.bash_logout
	.condarc
	.emacs
	.emacs.d
	.gitconfig
	.ipython
	.jupyter
	.zimrc
	.zshenv
	.zshrc
    )
    # Loop through each. If its a symlink, ignore, otherwise move to .backups
    for file in $dot_list; do
	path_file=$HOME/$file
	# Check if it exists as a file or a dir, and if its not a symlink
	if [[ -f $path_file || -d $path_file ]] && [[ ! -L $path_file ]]; then
	    # Move to backups dir, and append .bak to filename
	    mv $path_file $bak_dir/$file.bak
	fi
    done

    # Install dotfiles
    cd $dot_dir
    ./install
    # A bug with dotfiles is this sometimes needs to be run more than once to
    # fully work properly
    ./install
    cd
else
    printf "\nFound dotfiles repo. Skipping.\n"
fi


# # Third party software local installs

# Zsh
# Check if its not installed locally
if [[ ! -f $bin_dir/zsh ]]; then
    # Check this gist for sudo version of this
    # https://gist.github.com/apra93/7ecde84e36de6040cb1f2d023236c3b3
    printf "\nNo zsh executable found in $bin_dir. Downloading and
installing.\n"
    cd $dl_dir/
    
    # Set some variables
    zsh_root=zsh-$zsh_version
    zsh_tar=$zsh_root.tar.xz
    zsh_source=https://sourceforge.net/projects/zsh/files/zsh/$zsh_version/$zsh_tar/download

    # Download 
    wgetdl $zsh_source -O $zsh_tar    # Download from source and name it zsh_tar

    # unzip the .xz file
    # See this superuser post for the meaning of this line
    # https://superuser.com/questions/146814/unpack-tar-but-change-directory-name-to-extract-to
    mkdir -p $zsh_root; tar -xf $zsh_tar -C $zsh_root --strip-components=1    
    cd $zsh_root

    # Configure with .local, make, and install
    ./configure --prefix=$local_dir
    # Make things
    make
    # all tests should pass or skip
    make check
    make install

    # Check if the exec zsh line is in zshrc
    if ! grep -q "exec zsh" $local_bashrc; then
	# Exec zsh upon entering bash
	printf "\nexec zsh\n" >> $local_bashrc
    fi

    # Cleanup
    cd $dl_dir
    rm -rf $zsh_root $zsh_tar
    cd
else
    printf "\nZsh executable found. Skipping.\n"
fi

# Emacs
# Check if it doesn"t exist
if [[ ! -f $bin_dir/emacs ]]; then
    printf "\nNo local emacs installation found. Downloading and installing.\n"
    
    # Go to downloads
    cd $dl_dir

    # Set variables
    emacs_root=emacs-$emacs_version
    emacs_tar=$emacs_root.tar.xz
    emacs_source=https://ftp.gnu.org/pub/gnu/emacs/$emacs_tar
    
    # Download 
    wgetdl $emacs_source -O $emacs_tar	# Download and name it $emacs_tar

    # unzip the .xz file
    # See this superuser post for the meaning of this line
    # https://superuser.com/questions/146814/unpack-tar-but-change-directory-name-to-extract-to
    mkdir -p $emacs_root; tar -xf $emacs_tar -C $emacs_root --strip-components=1    
    cd $emacs_root

    # Autogen
    ./autogen.sh
    # Configure to the requirements of the machine
    ./configure \
    	--prefix=$lib_dir/emacs \
    	--bindir=$bin_dir \
    	--with-xpm=no \
	--with-png=no \
	--with-gif=no \
	--with-gnutls=no
    # Make things
    make && make install
       
    # Cleanup
    cd $dl_dir
    rm -rf $emacs_root $emacs_tar
    cd
else
    printf "\nLocal emacs found. Skipping.\n"    
fi


# Imagemagick
# Check if it doesn't exist
if [[ ! -f $bin_dir/magick ]]; then
    printf "\nNo instance of magick detected. Downloading and installing.\n"

    # Go to downloads
    cd $dl_dir

    # Set variables
    im_root=ImageMagick
    im_tar=$im_root.tar.xz
    im_source=https://imagemagick.org/download/$im_tar
    
    # Download 
    wgetdl $im_source -O $im_tar	# Download and name it $im_tar

    # unzip the .xz file
    # See this superuser post for the meaning of this line
    # https://superuser.com/questions/146814/unpack-tar-but-change-directory-name-to-extract-to
    mkdir -p $im_root; tar -xf $im_tar -C $im_root --strip-components=1  
    cd $im_root

    # Configure to the requirements of the machine
    ./configure \
	--prefix=$local_dir/ \
	--exec-prefix=$local_dir
    # Make things
    make && make install
       
    # Cleanup
    cd $dl_dir
    rm -rf $im_root $im_tar
    cd
else
    printf "\nMagick found. Skipping.\n"
fi
