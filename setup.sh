#!/bin/bash
# setup.sh: Install scripts

set -e

function install-canon-pixma-ip100 () {
    # Arch Linux: AUR: https://github.com/otterdahl/cnijfilter-ip100

    sudo apt install autoconf libtool-bin automake make gcc libcups2-dev libpopt-dev libgtk2.0-dev
    sudo apt-get remove cnjifilter-common || true
    cd $INSTALLDIR
    wget http://gdlp01.c-wss.com/gds/8/0100004118/01/cnijfilter-source-3.70-1.tar.gz
    tar zxf cnijfilter-source-3.70-1.tar.gz
    cd cnijfilter-source-3.70-1
    wget https://raw.githubusercontent.com/otterdahl/cnijfilter-ip100/master/cnij.patch
    wget https://raw.githubusercontent.com/otterdahl/cnijfilter-ip100/master/cups.patch
    wget https://raw.githubusercontent.com/otterdahl/cnijfilter-ip100/master/grayscale.patch
    wget https://raw.githubusercontent.com/otterdahl/cnijfilter-ip100/master/libpng15.patch
    wget https://raw.githubusercontent.com/otterdahl/cnijfilter-ip100/master/cnijnpr.patch
    wget "https://aur.archlinux.org/cgit/aur.git/plain/mychanges.patch?h=cnijfilter-common" -O mychanges.patch
    patch -p1 -i cups.patch
    patch -p1 -i libpng15.patch
    patch -p1 -i cnij.patch
    patch -p1 -i cnijnpr.patch
    patch -p1 -f -i mychanges.patch || true
    cd ppd
    patch -p0 < ../grayscale.patch
    cd ../libs
    ./autogen.sh --prefix=/usr --program-suffix=ip100
    make
    sudo make install
    cd ..

    for _dir in cngpij cnijfilter pstocanonij lgmon backend backendnet cngpijmon/cnijnpr
    do 
        cd ${_dir}
        ./autogen.sh --prefix=/usr --program-suffix=ip100 --enable-progpath=/usr/bin
        make LIBS=-ldl
        sudo make install
        cd ..
    done

    cd ../ppd
    ./autogen.sh --prefix=/usr --program-suffix=ip100
    make
    sudo make install
    cd ..

    LNGBITS=`getconf LONG_BIT`
    if [ $LNGBITS -eq 32 ]; then
      _arc=32
    else
      _arc=64
    fi
    sudo install -d /usr/lib/bjlib
    sudo install -m 755 303/database/* /usr/lib/bjlib
    sudo install -s -m 755 303/libs_bin${_arc}/*.so.* /usr/lib
    sudo install -s -m 755 com/libs_bin${_arc}/*.so.* /usr/lib
    sudo install -D LICENSE-cnijfilter-3.70EN.txt /usr/share/licenses/cnijfilter-ip100$/LICENSE-cnijfilter-3.70EN.txt
    sudo ln -fs /usr/lib/cups/filter/pstocanonijip100 /usr/lib/cups/filter/pstocanonij
    sudo ldconfig

    cd ..
    rm -rf cnijfilter-source-3.70-1
    rm -rf cnijfilter-source-3.70-1.tar.gz

    cat >/dev/stdout<<END

=======================================================
NOTE: It is possible to use the printer over bluetooth.
 1. Add the printer as a bluetooth device
    Use URI with format bluetooth://.... where ....
    is the bluetooth address without colons
 2. Add printer. Use driver "iP100 Ver.3.70" (Canon)
=======================================================
# sudo lpadmin -p canon-ip100 -E -v "bluetooth://...." -P /usr/share/cups/model/canonip100.ppd
# sudo lpoptions -d canon-ip100
END
}

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

function install-xbindkeys () {
    # Bind media keys
    # NOTE: These interferes with keybindings for spotify
    #       If you're using Ubuntu, use built in tools
    sudo apt-get -y install xbindkeys
    xbindkeys --defaults > ~/.xbindkeysrc || true
    cat >> ~/.xbindkeysrc<<END

"mpc toggle"
    m:0x0 + c:172
"mpc prev"
    m:0x0 + c:173
"mpc next"
    m:0x0 + c:171
END
}

function uninstall-xbindkeys () {
    sudo apt-get uninstall xbindkeys
}

# Install simple screencast tool
function install-screencast () {
    cd $INSTALLDIR
    git clone --recursive https://github.com/lolilolicon/FFcast.git
    cd FFcast
    ./bootstrap
    ./configure --enable-xrectsel --prefix /usr --libexecdir /usr/lib --sysconfdir /etc
    make
    sudo make install
    cd ..
    rm -rf FFcast

    # Patch FFcast subcommands
    # Adds support for screencast with sound (no aac)
    sudo cp ~/toolbox/ffcast_subcmd /usr/lib/ffcast/subcmd
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
    --install-canon-pixma-ip100
    --fix-citrix                    | --uninstall-citrix
    --install-mpd                   | --uninstall-mpd
    --install-xbindkeys             | --uninstall-xbindkeys
    --install-screencast            | --uninstall-screencast
    --install-opencbm
    --install-amitools
    --install-taskd
END
}

opwd="$PWD"     # Save current path
setdir

for cmd in "$1"; do
  case "$cmd" in
    --install-canon-pixma-ip100)
      install-canon-pixma-ip100
      ;;
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
    --install-xbindkeys)
      install-xbindkeys
      ;;
    --uninstall-xbindkeys)
      uninstall-xbindkeys
      ;;
    --install-screencast)
      install-screencast
      ;;
    --uninstall-screencast)
      uninstall-screencast
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
