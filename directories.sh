#!/bin/bash

# Script to ensure expeected directories are present

# Make sure basic folders are present
xdg-user-dirs-update

# Defining some directories
work_dir=$HOME/work
local_dir=$HOME/.local
local_bin_dir=$local_dir/bin
local_lib_dir=$local_dir/lib
local_etc_dir=$local_dir/etc
bak_dir=$local_dir/backups

# List of dirs to ensure existance besides the xdg user dirs. Add more if needed
base_dirs=(
    $work_dir
    $local_dir
    $local_bin_dir
    $local_lib_dir
    $local_etc_dir
    $bak_dir
)

for dir in "${base_dirs[@]}"; do
    mkdir -p $dir
done
