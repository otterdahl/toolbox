#!/bin/bash
# setup.sh: Install scripts

set -e

# Fix Citrix certificates
function fix-citrix () {
    # Fix certificates
    sudo rm -rf /opt/Citrix/ICAClient/keystore/cacerts
    sudo ln -s /etc/ssl/certs /opt/Citrix/ICAClient/keystore/cacerts
}

function uninstall-citrix () {
    sudo rm -rf /opt/Citrix/ICAClient/keystore/cacerts
    sudo apt-get -y remove --purge icaclient || echo "icaclient already removed"
    sudo apt-get -y autoremove
    sudo rm -rf $HOME/.ICAClient
}

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

function install-taskd () {
    cd $INSTALLDIR
    sudo apt-get -y install libgnutls28-dev cmake
    if [ ! -d "taskserver" ]; then
        git clone --recursive https://github.com/GothenburgBitFactory/taskserver.git
    fi
    cd taskserver
    git checkout 1.2.0
    cmake -DCMAKE_BUILD_TYPE=release .
    make
    sudo make install
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
    --fix-citrix                    | --uninstall-citrix
    --install-mpd                   | --uninstall-mpd
    --install-opencbm
    --install-amitools
    --install-taskd
END
}

opwd="$PWD"     # Save current path
setdir

for cmd in "$1"; do
  case "$cmd" in
    --fix-citrix)
      fix-citrix
      ;;
    --uninstall-citrix)
      uninstall-citrix
      ;;
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
    --install-taskd)
      install-taskd
      ;;
    *)
      usage
      ;;
  esac
done
cd "$opwd"      # Restore path
exit 0

# vim:ts=4:sw=4:et:cc=80:sts=4
