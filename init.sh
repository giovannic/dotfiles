#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=`pwd`/dotfiles
olddir=~/dotfiles_old             # old dotfiles backup directory

# create dotfiles_old in homedir
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p $olddir
echo "done"

# move any existing dotfiles in homedir to dotfiles_old directory, 
# then create symlinks from the homedir to any files in the ~/dotfiles 
# directory specified in $files
for file in $dir/*; do
    echo "Moving .$(basename $file) from ~ to $olddir"
    mv ~/.$(basename $file) ~/dotfiles_old/
    echo "Creating symlink from $file to home directory."
    ln -s $file ~/.$(basename $file)
done
