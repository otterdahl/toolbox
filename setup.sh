#!/bin/bash
# install.sh: Install essential apps and config files

set -e
# TODO: svtplay-dl, dropbox

# Install essential applications
function install-essential () {
    sudo apt-get install task vim lynx procmail mutt virt-manager \
         feh rdesktop cifs-utils git mplayer2 mpv screen catdoc powertop \
         wvdial bridge-utils pdftk pidgin-skype dvb-apps w-scan vlc \
         libav-tools at imagemagick curl
}

# Install private conf
function install-private-conf () {
    git clone otterdahl.org:~/config.git

    # Add symlinks to common apps
    ln -f -s ~/config/bash_aliases ~/.bash_aliases
    ln -f -s ~/config/vimrc ~/.vimrc
    ln -f -s ~/config/muttrc ~/.muttrc
    source ~/.bash_aliases

    # Tv channels
    mkdir -p ~/.tzap
    ln -f -s ~/config/channels.conf ~/.tzap/channels.conf

    # Transparent encrypted editing in vim
    gpg --import ~/config/public.key
    gpg --import ~/config/secret.key
    mkdir -p ~/.vim/plugin
    ln -f -s ~/config/gnupg.vim ~/.vim/plugin/gnupg.vim
    if grep -q GPG_TTY .bashrc; then
        :
    else
        cat >>~/.bashrc<<END
GPG_TTY=\`tty\`
export GPG_TTY 
END
    fi

    # Configure git
    echo "Configuring git"
    echo -n "Enter full name: "
    read FULLNAME
    echo -n "Enter e-mail address: "
    read EMAIL
    git config --global user.name $FULLNAME
    git config --global user.email $EMAIL
    git config --global core.editor vi
    git config --global push.default simple

    # Setup /etc/fstab with common mount points
    if grep -q i0davla-nas1 /etc/fstab; then
        :
    else
        sudo cat >>/etc/fstab<<END

//192.168.2.3/Backup                 /mnt/i0davla-nas1-b cifs   noauto,user,credentials=/home/i0davla/config/smb-i0davla-nas1 0 0
//192.168.2.3/Music                  /mnt/i0davla-nas1-m cifs   noauto,user,credentials=/home/i0davla/config/smb-i0davla-nas1 0 0
//192.168.2.3/Video                  /mnt/i0davla-nas1-v cifs   noauto,user,credentials=/home/i0davla/config/smb-i0davla-nas1 0 0
//192.168.2.4/Video                  /mnt/i0davla-nas2-v cifs   noauto,user,credentials=/home/i0davla/config/smb-i0davla-nas1 0 0

//192.168.2.3/usbshare2              /mnt/dl2            cifs   noauto,user,credentials=/home/i0davla/config/smb-i0davla-nas1 0 0
END
        if [ ! -d "/mnt/i0davla-nas1-b" ]; then sudo mkdir "/mnt/i0davla-nas1-b"; fi
        if [ ! -d "/mnt/i0davla-nas1-m" ]; then sudo mkdir "/mnt/i0davla-nas1-m"; fi
        if [ ! -d "/mnt/i0davla-nas1-v" ]; then sudo mkdir "/mnt/i0davla-nas1-v"; fi
        if [ ! -d "/mnt/i0davla-nas2-v" ]; then sudo mkdir "/mnt/i0davla-nas2-v"; fi
        if [ ! -d "/mnt/dl2" ]; then sudo mkdir "/mnt/dl2"; fi
    fi
}

# BankId (Fribid)
function install-fribid () {
    git clone https://github.com/otterdahl/OpenSC.git $INSTALLDIR/OpenSC
    cd $INSTALLDIR/OpenSC
    ./bootstrap
    ./configure --prefix=/usr --sysconfdir=/etc/opensc --enable-openssl --enable-sm
    make
    sudo make install
    sudo sed -i "s/# lock_login = true/lock_login = true/" /etc/opensc.conf
    echo opensc hold | sudo dpkg --set-selections
    git clone https://github.com/samuellb/fribid.git $INSTALLDIR/fribid
    cd $INSTALLDIR/fribid
    make
    sudo make install
    echo "NOTE: Leaving $INSTALLDIR/fribid and $INSTALLDIR/OpenSC."
    echo "They are needed for uninstallation"
}

function uninstall-fribid () {
    cd $INSTALLDIR/OpenSC
    sudo make uninstall
    cd $INSTALLDIR/fribid
    sudo make uninstall
    cd ..
    rm -rf $INSTALLDIR/OpenSC
    rm -rf $INSTALLDIR/fribid
    echo opensc install | sudo dpkg --set-selections
}

# Wifi drivers for Edimax AC-1200 (7392:a822) and Zyxel NWD6505
function install-edimax () {
    cd $INSTALLDIR
    if [ ! -d rtl8812AU_8821AU_linux ]; then
        git clone https://github.com/abperiasamy/rtl8812AU_8821AU_linux.git
        cd rtl8812AU_8821AU_linux
    else
        cd rtl8812AU_8821AU_linux
        git pull
    fi
    make
    sudo make install
    sudo modprobe 8812au
    echo "NOTE: Leaving $INSTALLDIR/rtl8812AU_8821AU_linux. It is needed for uninstallation"
}

function uninstall-edimax () {
    sudo modprobe -r 8812au
    cd $INSTALLDIR/rtl8812AU_8821AU_linux
    sudo make uninstall
    cd ..
    rm -rf rtl8812AU_8821AU_linux
}

# Scanner driver for Canon P-150
function install-canon-p150 () {
    cd $INSTALLDIR

    # Download driver
    mkdir -p canon
    cd canon
    wget http://downloads.canon.com/cpr/software/scanners/150_LINUX_V10.zip
    unzip -q 150_LINUX_V10.zip
    rm 150_LINUX_V10.zip

    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        # x64 installation
        # taken from: http://lowerstrata.blogspot.se/2010/07/canon-p-150-and-linux.html
        sudo apt-get install libusb-dev
        tar xfz cndrvsane-p150-1.00-0.2.tar.gz
        wget https://alioth.debian.org/frs/download.php/file/2318/sane-backends-1.0.19.tar.gz
        tar xfz sane-backends-1.0.19.tar.gz
        cd sane-backends-1.0.19
        ./configure
        make
        cd ../cndrvsane-p150-1.00-0.2
        fakeroot make -f debian/rules binary
        cd ..
        sudo dpkg -i cndrvsane-p150_1.00-0.2_amd64.deb
        sudo ln -s /opt/Canon/lib/canondr /usr/local/lib/canondr
    else
        # x86-bit installation
        sudo dpkg -i cndrvsane-p150_1.00-0.2_i386.deb
    fi
    cd ..
    rm -rf $INSTALLDIR/canon
}

function uninstall-canon-p150 () {
    sudo rm /usr/local/lib/canondr
    sudo dpkg -r cndrvsane-p150
}

# Printer driver Canon Pixma iP100
function install-canon-pixma-ip100 () {
    cd $INSTALLDIR

    # For Ubuntu 14.04: Driver depends on libtiff4, but it is needs manual installation
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        wget http://archive.ubuntu.com/ubuntu/pool/universe/t/tiff3/libtiff4_3.9.7-2ubuntu1_amd64.deb
        sudo dpkg -i libtiff4_3.9.7-2ubuntu1_amd64.deb
        rm libtiff4_3.9.7-2ubuntu1_amd64.deb
    else
        wget http://archive.ubuntu.com/ubuntu/pool/universe/t/tiff3/libtiff4_3.9.7-2ubuntu1_i386.deb
        sudo dpkg -i libtiff4_3.9.7-2ubuntu1_i386.deb
        rm libtiff4_3.9.7-2ubuntu1_i386.deb
    fi

    # Taken from
    # http://www.canon-europe.com/Support/Consumer_Products/products/printers/InkJet/PIXMA_iP_series/iP100.aspx?type=download&language=&os=Linux
    wget http://gdlp01.c-wss.com/gds/0/0100001190/02/cnijfilter-ip100series-3.70-1-deb.tar.gz
    tar xzf cnijfilter-ip100series-3.70-1-deb.tar.gz
    rm cnijfilter-ip100series-3.70-1-deb.tar.gz
    cd cnijfilter-ip100series-3.70-1-deb
    sudo yes "Q" | ./install.sh
    cd ..
    rm -rf cnijfilter-ip100series-3.70-1-deb
    cat >/dev/stdout<<END
=======================================================
NOTE: It is possible to use the printer over bluetooth.
 1. Add the printer as a bluetooth device
 2. Add printer. Use driver "iP100 Ver.3.70" (Canon)
=======================================================
END
}

# Citrix Receiver 13.2
function install-citrix () {
    cd $INSTALLDIR
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        sudo dpkg --add-architecture i386 # only needed once
        sudo apt-get update

        # From https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-13-2.html
        wget `curl https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-13-2.html |
        grep "icaclient_13.2.0.322243_amd64.deb?__gda__" |
        sed -e 's/.*rel=\"\(.*\)\" id.*/http:\1/p' | uniq` -O icaclient_13.2.0_amd64.deb

        sudo dpkg -i icaclient_13.2.0_amd64.deb || true
        sudo apt-get -fy install
        rm icaclient_13.2.0_amd64.deb

        # Fix Firefox installation
        # Starting with Citrix Receiver 13.1, the 64-bit version of Citrix
        # Receiver switched from a 32-bit plugin (using nspluginwrapper to
        # allow it to run within a 64-bit browser) to a native 64-bit plugin.
        # However, the install script still configures the plugin to run
        # within nspluginwrapper, which doesn't work with a 64-bit plugin.
        # This will reconfigure the plugin to run without nspluginwrapper. 
        sudo rm -f /usr/lib/mozilla/plugins/npwrapper.npica.so /usr/lib/firefox/plugins/npwrapper.npica.so
        sudo rm -f /usr/lib/mozilla/plugins/npica.so
        sudo ln -s /opt/Citrix/ICAClient/npica.so /usr/lib/mozilla/plugins/npica.so
    else
        # TODO: 32-bit installation not tested
        # From https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-13-2.html
        wget `curl https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-13-2.html |
        grep "icaclient_13.2.0.322243_i386.deb?__gda__" |
        sed -e 's/.*rel=\"\(.*\)\" id.*/http:\1/p' | uniq` -O icaclient_13.2.0_i386.deb

        sudo dpkg -i icaclient_13.2.0_i386.deb || true
        sudo apt-get -fy install
        rm icaclient_13.2.0_i386.deb
    fi

    # Symlink certificates from Firefox
    sudo ln -f -s /usr/share/ca-certificates/mozilla/* /opt/Citrix/ICAClient/keystore/cacerts/
    sudo c_rehash /opt/Citrix/ICAClient/keystore/cacerts

    echo "In Firefox, go to Tools -> Add-ons -> Plugins, and make sure the 'Citrix Receiver for Linux' plugin is set to 'Always Activate'. "
}

function uninstall-citrix () {
    sudo rm -rf /opt/Citrix/ICAClient/keystore/cacerts
    sudo apt-get -y remove --purge icaclient || echo "icaclient already removed"
    sudo apt-get -y autoremove
}

function install-pidgin-sipe () {
    cd $INSTALLDIR

    # Uninstall any pidgin-sipe from repository
    sudo apt-get remove pidgin-sipe

    # Install latest pidgin-sipe from source
    sudo apt-get install autotools-dev pkg-config libglib2.0-dev \
        libgtk2.0-dev libpurple-dev libtool intltool comerr-dev \
        libnss3-dev libxml2-dev pidgin

    if [ ! -d siplcs ]; then
        git clone -n git+ssh://mob@repo.or.cz/srv/git/siplcs.git
        cd siplcs
        git checkout -b mob --track origin/mob
    else
        cd siplcs
        git pull
    fi
    ./git-build.sh --prefix=/usr
    sudo make install
    cd ..
    echo "NOTE: Leaving $INSTALLDIR/siplcs. It is needed for uninstallation"
}

function uninstall-pidgin-sipe () {
    cd $INSTALLDIR
    cd siplcs
    sudo make uninstall
    cd ..
    rm -rf siplcs

    # Uninstall any pidgin-sipe from repository
    sudo apt-get remove pidgin-sipe
}

function install-spotify () {
    if grep -q repository.spotify.com /etc/apt/sources.list; then
        :
    else
        echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D2C19886
        sudo apt-get update
    fi
    sudo apt-get install spotify-client

    # Missing libgcrypt11 in Ubuntu 15.04
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        # 64-bit
        wget http://security.ubuntu.com/ubuntu/pool/main/libg/libgcrypt11/libgcrypt11_1.5.4-2ubuntu1.1_amd64.deb
        sudo dpkg -i libgcrypt11_1.5.4-2ubuntu1.1_amd64.deb
        rm libgcrypt11_1.5.4-2ubuntu1.1_amd64.deb
    else
        # 32-bit
        wget http://security.ubuntu.com/ubuntu/pool/main/libg/libgcrypt11/libgcrypt11_1.5.4-2ubuntu1.1_i386.deb
        sudo dpkg -i libgcrypt11_1.5.4-2ubuntu1.1_i386.deb
        rm libgcrypt11_1.5.4-2ubuntu1.1_i386.deb
    fi
}

function uninstall-spotify () {
    sudo apt-get remove spotify-client
    sudo sed -i '/deb http:\/\/repository.spotify.com stable non-free//'
    sudo apt-get update
}

# VMware-player 6.0.3
function install-vmware-player () {
    cd $INSTALLDIR
    # NOTE: Only x64
    # From: https://my.vmware.com/web/vmware/free#desktop_end_user_computing/vmware_player/6_0
    wget "https://download3.vmware.com/software/player/file/VMware-Player-6.0.3-1895310.x86_64.bundle?HashKey=949bef007e4b02adad3dbe51b3133322&amp;params=%7B%22sourcefilesize%22%3A%22191+MB%22%2C%22dlgcode%22%3A%22PLAYER-603%22%2C%22languagecode%22%3A%22en%22%2C%22source%22%3A%22DOWNLOADS%22%2C%22downloadtype%22%3A%22manual%22%2C%22eula%22%3A%22N%22%2C%22downloaduuid%22%3A%22911beac5-fb6c-4de8-906f-9102856b2293%22%2C%22purchased%22%3A%22N%22%2C%22dlgtype%22%3A%22Product+Binaries%22%2C%22productversion%22%3A%226.0.3%22%2C%22productfamily%22%3A%22VMware+Player%22%7D&amp;AuthKey=1410271621_7a7073b9bc7d9e40dfd6dfa154e34140" \
        -O VMware-Player-6.0.3-1895310.x86_64.bundle
    chmod +x VMware-Player-6.0.3-1895310.x86_64.bundle
    sudo ./VMware-Player-6.0.3-1895310.x86_64.bundle
    echo -------------------------------------------------------------------------------------------------------------
    echo "NOTE: Leaving VMware-Player-6.0.3-1895310.x86_64.bundle in $INSTALLDIR. It is needed for uninstallation"
}

function uninstall-vmware-player () {
    cd $INSTALLDIR
    sudo ./VMware-Player-6.0.3-1895310.x86_64.bundle --uninstall-component=vmware-player
    rm VMware-Player-6.0.3-1895310.x86_64.bundle
}

function install-mpd () {
    sudo apt-get install mpd mpc ncmpcpp xbindkeys
    mkdir -p ~/.config/mpd/playlists
    mkdir -p ~/.ncmpcpp
    touch ~/.config/mpd/pid
    touch ~/.config/mpd/tag_cache
    ln -s ~/config/ncmpcpp_keys ~/.ncmpcpp/keys

    # On Raspbian. Uses ~/.mpdconf
    # On Ubuntu 14.04. Uses ~/.config/mpd/mpd.conf
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'armv6l' ]; then
        ln -s ~/config/mpd_pi.conf ~/.mpdconf
    elif [ ${MACHINE_TYPE} == 'x86_64' || ${MACHINE_TYPE} == 'x86' ]; then
        ln -s ~/config/mpd.conf ~/.config/mpd/mpd.conf

        # Bind media keys
        # TODO: These interferes with keybindings for spotify
        sudo apt-get -y xbindkeys
        xbindkeys --defaults > ~/.xbindkeysrc
        cat >> ~/.xbindkeysrc<END

"mpc toggle"
    m:0x0 + c:172
"mpc prev"
    m:0x0 + c:173
"mpc next"
    m:0x0 + c:171
END
    fi


    # Don't run mpd as a system service
    # -  Changing configuration files doesn't require root
    # -  Multiple audio sources causes conflicts when running
    #          several pulse audio daemons
    sudo service mpd stop
    sudo sed -i "s/START_MPD=true/START_MPD=false/" /etc/default/mpd

    echo "-----------------------------------------------------------"
    echo "Add music to $HOME/Musik. Then start listening using ncmpcc"
    echo "Run xkeybindings to use keybindings (only x86/x86_64 for now)"
}

function uninstall-mpd () {
    sudo apt-get remove mpd mpc ncmpcpp
}

function install-spotifyripper () {
    cd $INSTALLDIR

    # libspotify from spotify
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        wget https://developer.spotify.com/download/libspotify/libspotify-12.1.51-Linux-x86_64-release.tar.gz
        tar xfz libspotify-12.1.51-Linux-x86_64-release.tar.gz
        cd libspotify-12.1.51-Linux-x86_64-release
        sudo make install
        cd ..
        rm libspotify-12.1.51-Linux-x86_64-release.tar.gz
    elif [ ${MACHINE_TYPE} == 'x86' ]; then
        wget https://developer.spotify.com/download/libspotify/libspotify-12.1.51-Linux-i686-release.tar.gz
        tar xfz libspotify-12.1.51-Linux-i686-release.tar.gz
        cd libspotify-12.1.51-Linux-i686-release
        sudo make install
        cd ..
        rm libspotify-12.1.51-Linux-i686-release.tar.gz
    elif [ ${MACHINE_TYPE} == 'armv6l' ]; then
	wget https://developer.spotify.com/download/libspotify/libspotify-12.1.103-Linux-armv6-bcm2708hardfp-release.tar.gz
        tar xfz libspotify-12.1.103-Linux-armv6-bcm2708hardfp-release.tar.gz
        cd libspotify-12.1.103-Linux-armv6-bcm2708hardfp-release
        sudo make install
        cd ..
        rm libspotify-12.1.103-Linux-armv6-bcm2708hardfp-release.tar.gz
    else
        echo "libspotify: unsupported platform $MACHINE_TYPE"
        exit 1
    fi

    # Requires eyeD3. eyeD3 cannot be run from paths using international
    # characters
    cd $HOME
    git clone https://github.com/robbeofficial/spotifyripper

    sudo apt-get install -y python-dev lame python-pip libffi-dev
    sudo pip install -U pyspotify
    if [ ${MACHINE_TYPE} == 'armv6l' ]; then
    	sudo pip install eyeD3
    else
    	sudo pip install eyeD3 --allow-external eyeD3 --allow-unverified eyeD3
    fi
    ln -s $HOME/config/spotify_appkey.key $HOME/spotifyripper/spotify_appkey.key
    echo "----------------------------------------------"
    echo "Spotifyripper installed in $HOME/spotifyripper"
}

function uninstall-spotifyripper () {
    cd $INSTALLDIR
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        cd libspotify-12.1.51-Linux-x86_64-release
        sudo make uninstall
        cd ..
        rm -rf libspotify-12.1.51-Linux-x86_64-release
    elif [ ${MACHINE_TYPE} == 'x86' ]; then
        cd libspotify-12.1.51-Linux-i686-release
        sudo make uninstall
        cd ..
        rm -rf libspotify-12.1.51-Linux-i686-release
    elif [ ${MACHINE_TYPE} == 'armv6l' ]; then
        cd libspotify-12.1.103-Linux-armv6-bcm2708hardfp-release
        sudo make uninstall
        cd ..
        rm -rf libspotify-12.1.103-Linux-armv6-bcm2708hardfp-release
    fi

    cd $HOME
    rm -rf spotifyripper
}

# Install wvdial
function install-wvdial () {
    sudo apt-get install wvdial
    sudo rm -f /etc/wvdial.conf
    sudo usermod -a -G dialout $USER || true
    sudo usermod -a -G dip $USER || true
    sudo ln -s $HOME/config/wvdial.conf /etc/wvdial.conf
    echo "Remember to logout and login for the changes to take affect"
}

function uninstall-wvdial () {
    sudo apt-get remove wvdial
    sudo rm /etc/wvdial.conf
}

function install-youtube-dl () {
    sudo wget https://yt-dl.org/downloads/2014.09.29.2/youtube-dl -O /usr/local/bin/youtube-dl
    sudo chmod a+x /usr/local/bin/youtube-dl
}

# Experimental Pulseaudio with Airplay support
function install-raop2 () {
    sudo apt-get install build-essential paprefs git pulseaudio-module-raop intltool libjack0
    sudo apt-get build-dep pulseaudio
    cd $INSTALLDIR
    if [ ! -d pulseaudio-raop2 ]; then
        git clone https://github.com/hfujita/pulseaudio-raop2.git
        cd pulseaudio-raop2
    else
        cd pulseaudio-raop2
        git pull
    fi
    ./autogen.sh
    CFLAGS="-ggdb3 -O0" LDFLAGS="-ggdb3" ./configure --prefix=$HOME --enable-x11 --disable-hal-compat
    make
}

function enable-raop2 () {
    zenity --info --text zenity --info --text "Turn on 'Make discoverable Apple AirTunes sound devices available locally'"
    paprefs

    mkdir -p ~/.pulse
    echo "autospawn=no" > ~/.pulse/client.conf
    pulseaudio -k || true
    cd $INSTALLDIR/pulseaudio-raop2
    ./src/pulseaudio -n -F src/default.pa -p $(pwd)/src/ --log-time=1 -vvvv 2>&1 | tee pulse.log
}

function disable-raop2 () {
    # Reenable original pulseaudio
    pulseaudio -D
    if [ -e ~/.pulse/client.conf ]; then
        sed -i "s/autospawn=no//" ~/.pulse/client.conf
    fi
}

function install-office2010 () {
    # NOTE: Installation fails (But why?)
    sudo apt-get install wine winbind
    cd $INSTALLDIR
    if [ ! -f office-2010-pro-plus.x86.en-us.iso ]; then
        echo "Fetching installation media"
        IS_MOUNTED=`mount | grep nas1-b` || true
        if [ -z "${IS_MOUNTED}" ]; then
            echo "Mounting backup drive"
            mount /mnt/i0davla-nas1-b
        fi
        echo "Copying ISO"
        cp /mnt/i0davla-nas1-b/iso/office-2010-pro-plus.x86.en-us.iso .
    fi
    echo "Mounting installation media"
    sudo mkdir /mnt/office2010
    sudo mount $INSTALLDIR/office-2010-pro-plus.x86.en-us.iso /mnt/office2010 -o loop
    echo "Copying installation media"
    cp -r /mnt/office2010 $HOME
    mkdir -p $HOME/.local/share/wineprefixes/msoffice2010
    export WINEPREFIX="$HOME/.local/share/wineprefixes/msoffice2010/"
    export WINEARCH=win32
    zenity --info --text "Just close the wine settings"
    winecfg
    cd $HOME/office2010
    wine setup.exe || true
    zenity --info --text "Set the following overrides: riched20 (native), winhttp (native, builtin)"
    winecfg

    # Cleanup
    sudo rm -rf $HOME/office2010
    sudo umount /mnt/office2010
    sudo rmdir /mnt/office2010
    if [ ! -z "${IS_MOUNTED}" ]; then
        echo "Unmounting backup drive"
        umount /mnt/i0davla-nas1-b
    fi
    cd $INSTALLDIR
    #rm office-2010-pro-plus.x86.en-us.iso
}

function uninstall-office2010 () {
    rm -rf $HOME/.local/share/wineprefixes/msoffice2010
}

function fix-steam-ubuntu1504 () {
    # Fix steam on Ubuntu 15.04
    # Only 32-bit
    cd $HOME/.steam/steam/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu
    # 64-bit: cd $HOME/.steam/steam/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu
    mv libstdc++.so.6 libstdc++.so.6.bak
}

# Find suitable installation dir
function setdir () {
    if [ -d "$HOME/Hämtningar" ]; then
        INSTALLDIR="$HOME/Hämtningar"
    elif [ -d "$HOME/Downloads" ]; then
        INSTALLDIR="$HOME/Downloads"
    else
        INSTALLDIR="$HOME"
    fi
}

function usage () {
    cat >/dev/stdout<<END
$0 [option]
    --install-essential
    --install-private-conf
    --install-fribid                | --uninstall-fribid
    --install-edimax                | --uninstall-edimax
    --install-canon-p150            | --uninstall-canon-p150
    --install-canon-pixma-ip100
    --install-citrix                | --uninstall-citrix
    --install-pidgin-sipe           | --uninstall-pidgin-sipe
    --install-spotify               | --uninstall-spotify
    --install-vmware-player         | --uninstall-vmware-player
    --install-mpd                   | --uninstall-mpd
    --install-spotifyripper         | --uninstall-spotifyripper
    --install-wvdial                | --uninstall-wvdial
    --install-youtube-dl
    --install-raop2
    --enable-raop2
    --disable-raop2
    --install-office2010            | --uninstall-office2010
    --fix-steam-ubuntu1504
END
}

opwd="$PWD"     # Save current path
setdir

for cmd in "$1"; do
  case "$cmd" in
    --install-essential)
      install-essential
      ;;
    --install-private-conf)
      install-private-conf
      ;;
    --install-fribid)
      install-fribid  
      ;;
    --uninstall-fribid)
      uninstall-fribid  
      ;;
    --install-edimax)
      install-edimax
      ;;
    --uninstall-edimax)
      uninstall-edimax
      ;;
    --install-canon-p150)
      install-canon-p150
      ;;
    --uninstall-canon-p150)
      uninstall-canon-p150
      ;;
    --install-canon-pixma-ip100)
      install-canon-pixma-ip100
      ;;
    --install-citrix)
      install-citrix
      ;;
    --uninstall-citrix)
      uninstall-citrix
      ;;
    --install-pidgin-sipe)
      install-pidgin-sipe
      ;;
    --uninstall-pidgin-sipe)
      uninstall-pidgin-sipe
      ;;
    --install-spotify)
      install-spotify
      ;;
    --uninstall-spotify)
      uninstall-spotify
      ;;
    --install-vmware-player)
      install-vmware-player
      ;;
    --uninstall-vmware-player)
      uninstall-vmware-player
      ;;
    --install-mpd)
      install-mpd
      ;;
    --uninstall-mpd)
      uninstall-mpd
      ;;
    --install-spotifyripper)
      install-spotifyripper
      ;;
    --uninstall-spotifyripper)
      uninstall-spotifyripper
      ;;
    --install-wvdial)
      install-wvdial
      ;;
    --uninstall-wvdial)
      uninstall-wvdial
      ;;
    --install-youtube-dl)
      install-youtube-dl
      ;;
    --install-raop2)
      install-raop2
      ;;
    --enable-raop2)
      enable-raop2
      ;;
    --disable-raop2)
      disable-raop2
      ;;
    --install-office2010)
      install-office2010
      ;;
    --uninstall-office2010)
      uninstall-office2010
      ;;
    --fix-steam-ubuntu1504)
      fix-steam-ubuntu1504
      ;;
    *)
      usage
      ;;
  esac
done
cd "$opwd"      # Restore path
exit 0
