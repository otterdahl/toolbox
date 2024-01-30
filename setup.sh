#!/bin/bash
# setup.sh: Install scripts

set -e

function install-mpd () {
    sudo apt-get -y install mpd mpc ncmpcpp
    mkdir -p ~/.config/mpd/playlists
    mkdir -p ~/.ncmpcpp
    ln -s ~/.ncmpcpp/bindings ~/config/ncmpcpp_bindings
    touch ~/.config/mpd/pid
    touch ~/.config/mpd/tag_cache

    # On Raspbian. Uses ~/.mpdconf
    # On Ubuntu 14.04. Uses ~/.config/mpd/mpd.conf
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'armv6l' ]; then
        ln -fs ~/config/mpd_pi.conf ~/.mpdconf
    else
        ln -fs ~/config/mpd.conf ~/.config/mpd/mpd.conf
    fi

    # Don't run mpd as a system service
    # -  Changing configuration files doesn't require root
    # -  Multiple audio sources causes conflicts when running
    #          several pulse audio daemons
    sudo service mpd stop

    # systemd-style
    sudo systemctl stop mpd.service
    sudo systemctl disable mpd.service
    sudo systemctl stop mpd.socket
    sudo systemctl disable mpd.socket
}

function uninstall-mpd () {
    sudo apt-get remove mpd mpc ncmpcpp
}

# Install opencbm
# Tested on raspbian, ubuntu
function install-opencbm () {
    cd $INSTALLDIR
    git clone https://github.com/cc65/cc65.git
    cd cc65
    make
    sudo make install PREFIX=/usr

    cd $INSTALLDIR
    sudo apt-get install libusb-dev libncurses5-dev
    git clone https://github.com/OpenCBM/OpenCBM.git
    cd OpenCBM
    git checkout v0.4.99.99a
    make -f LINUX/Makefile opencbm plugin-xum1541
    sudo make -f LINUX/Makefile install install-plugin-xum1541
    sudo ldconfig
}

# Install amitools
function install-amitools () {
    cd $INSTALLDIR
    sudo apt-get -y install cython
    git clone https://github.com/cnvogelg/amitools
    sudo python setup.py install
}

# Find suitable installation dir
function setdir () {
    INSTALLDIR="$HOME/build-repos"
    if [ ! -d "$INSTALLDIR" ]; then
        mkdir "$INSTALLDIR"
    fi
}

function usage () {
    cat >/dev/stdout<<END
$0 [option]
    --install-mpd                   | --uninstall-mpd
    --install-opencbm
    --install-amitools
END
}

opwd="$PWD"     # Save current path
setdir

for cmd in "$1"; do
  case "$cmd" in
    --install-mpd)
      install-mpd
      ;;
    --uninstall-mpd)
      uninstall-mpd
      ;;
    --install-opencbm)
      install-opencbm
      ;;
    --install-amitools)
      install-amitools
      ;;
    --install-amitools)
      install-amitools
      ;;
    *)
      usage
      ;;
  esac
done
cd "$opwd"      # Restore path
exit 0

# vim:ts=4:sw=4:et:cc=80:sts=4
