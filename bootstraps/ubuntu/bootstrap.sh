#!/usr/bin/env bash

if [ `uname` != "Linux" ]; then
    echo "ERROR: bootstrap.sh is only supported on a Linux system."
    exit 1
fi

DEVKIT="git git-review build-essential make vim"
PYDEVKIT="python-pip python-virtualenv python-dev python3-dev python-tox"
TOOLS="curl htop man manpages screen realpath wget"

apt-get -y update
apt-get -y dist-upgrade
apt-get -y install ${DEVKIT} ${PYDEVKIT} ${TOOLS}
apt-get clean all
apt-get autoremove
easy_install -U pip
pip install virtualenv --upgrade

VIMRC_FILE=~/.vimrc
cat <<VIMRC_OPTS >$VIMRC_FILE
set shiftwidth=4
set tabstop=4
set expandtab
set softtabstop=4
set smarttab
set backspace=indent,eol,start
set nocompatible
set paste
set ruler
syntax on
filetype plugin on
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/
VIMRC_OPTS
