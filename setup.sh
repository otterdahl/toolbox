#!/bin/bash
# setup.sh: Install essential apps and config files
# Targets support for: Ubuntu 14.04, 15.10 and Raspbian

set -e
# TODO: tellstick, PCTV nanoStick T2 290e

# Install essential applications
function install-essential () {
    sudo apt-get install task vim lynx cifs-utils git screen catdoc powertop \
         wvdial bridge-utils pdftk dvb-apps w-scan libav-tools at imagemagick \
         curl opus-tools irssi bitlbee-libpurple
    
    # Desktop
    sudo apt-get install virt-manager i3 feh rdesktop mpv mplayer2 vlc thunar \
        gnome-icon-theme-full scrot xscreensaver autocutsel rxvt-unicode-256color \
        libjson-perl

    # Email
    sudo apt-get install mutt procmail offlineimap msmtp

    # Ubuntu 15.04+ adds svtplay-dl
    UBUNTU_VER=`lsb_release -r | tr '.' ' ' | awk '{print $2}'`
    if [ "$UBUNTU_VER" -ge 15 ]; then
        sudo apt-get -y install svtplay-dl
    fi
}

function install-macbook () {
    # fan control daemon for Apple MacBook / MacBook Pro computers
    sudo apt-get install macfanctld

    # For MacbookPro 8,2
    # See https://help.ubuntu.com/community/MacBookPro8-2/Raring
    MODEL=`sudo dmidecode -s system-product-name`
    if [ $MODEL == 'MacBookPro8,2' ]; then
        # How to boot
        # -----------
        # # On GRUB edit the entry for Ubuntu; add the following after
        # # insmod ext2
        # outb 0x728 1 # Switch select
        # outb 0x710 2 # Switch display
        # outb 0x740 2 # Switch DDC
        # outb 0x750 0 # Power down discrete graphics
        # # Add after quiet splash - 
        # quiet splash i915.lvds_channel_mode=2 i915.modeset=1 i915.lvds_use_ssc=0
        # This will disable the radeon card and only use the integrated card. 

        # Permanent installation
        # ----------------------
        # NOTE: untested
        # /etc/grub.d/10_linux (before insmod gzio)
        # echo "    outb 0x728 1" | sed "s/^/$submenu_indentation/"
        # echo "    outb 0x710 2" | sed "s/^/$submenu_indentation/"
        # echo "    outb 0x740 2" | sed "s/^/$submenu_indentation/"
        # echo "    outb 0x750 0" | sed "s/^/$submenu_indentation/"

        # /etc/default/grub
        # NOTE: untested
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash i915.lvds_channel_mode=2 i915.modeset=1 i915.lvds_use_ssc=0\/" /etc/default/grub
        sudo update-grub

        # Refind (for selecting between Intel and AMD graphics)
        sudo apt-get install refind
        sudo /usr/share/refind/install.sh

        echo "On boot:"
        echo " 1, first choice is for booting with integrated card (intel)"
        echo " 2, second choice is for booting with dedicated card (radeon)"
    fi
}

# Install private conf
function install-private-conf () {
    if [ ! -d ~/config ]; then
        git clone otterdahl.org:~/config.git ~/config
    else
        cd ~/config
        git pull
        cd $INSTALLDIR
    fi

    # Add symlinks to common apps
    ln -f -s ~/config/bash_aliases ~/.bash_aliases
    ln -f -s ~/config/vimrc ~/.vimrc
    ln -f -s ~/config/muttrc ~/.muttrc
    source ~/.bash_aliases

    # Tv channels
    mkdir -p ~/.tzap
    ln -f -s ~/config/channels.conf ~/.tzap/channels.conf

    # Transparent encrypted editing in vim
    gpg --import ~/config/public.key || echo "Key already added"
    gpg --import ~/config/secret.key || echo "Key already added"
    mkdir -p ~/.vim/plugin
    ln -f -s ~/config/gnupg.vim ~/.vim/plugin/gnupg.vim
    if grep -q GPG_TTY ~/.bashrc; then
        :
    else
        cat >>~/.bashrc<<END
GPG_TTY=\`tty\`
export GPG_TTY 
END
    fi

    # Configure git
    if [ ! -n $(git config user.email) ]; then
        echo "Configuring git"
        echo -n "Enter full name: "; read FULLNAME
        echo -n "Enter e-mail address: "; read EMAIL
        git config --global --replace-all user.name "$FULLNAME"
        git config --global user.email $EMAIL
        git config --global core.editor vi
        git config --global push.default simple
    fi

    # Configure taskwarrior
    ln -f -s ~/config/taskrc ~/.taskrc

    # Configure i3-wm
    mkdir -p ~/.i3/
    ln -f -s ~/config/i3config ~/.i3/config

    # Configure i3status
    # Used for custom i3 status with my_i3status.pl
    ln -f -s ~/config/i3status.conf ~/.i3status.conf

    # Configure xsessionrc
    # Used for appending $PATH to use with dmenu (bashrc won't do)
    ln -f -s ~/config/xsessionrc ~/.xsessionrc

    # Configure Xresources
    # Used for adding colors to urxvt (in i3)
    ln -f -s ~/config/Xresources ~/.Xresources

    # Configure offlineimap
    ln -f -s ~/config/offlineimaprc ~/.offlineimaprc

    # Set irssi config
    ln -f -s ~/config/irssi ~/.irssi

    # Configure crontab
    crontab ~/config/crontab

    # Add group wheel (wpa_supplicant) and add current user to it
    if [ ! -n "$(grep wheel /etc/group)" ]; then 
        sudo groupadd wheel
        sudo usermod -a -G  wheel $USER
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

# Pipelight. To watch HBO Nordic in firefox
function install-pipelight () {
    # Pipelight installation
    sudo add-apt-repository ppa:pipelight/stable
    sudo apt-get update
    sudo apt-get install --install-recommends pipelight-multi
    sudo pipelight-plugin --update

    sudo apt-get remove flashplugin-installer

    sudo pipelight-plugin --enable flash
    sudo pipelight-plugin --enable widevine
    sudo pipelight-plugin --enable silverlight

    sudo pipelight-plugin --update
    sudo pipelight-plugin --create-mozilla-plugins
}

function uninstall-pipelight () {
    sudo apt-get -y remove pipelight-multi
    sudo apt-get -y autoremove
    sudo apt-get install flashplugin-installer
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
    wget -q http://downloads.canon.com/cpr/software/scanners/150_LINUX_V10.zip
    SHA1=`sha1sum 150_LINUX_V10.zip | awk '{print $1}'`
    if [ ! "$SHA1" == "8adac963b318ce28d536c8681aed0e5da70a6d41" ]; then
        echo "Checksum missmatch"
        cd $INSTALLDIR
        rm -rf $INSTALLDIR/canon
        exit 1;
    fi

    unzip -q 150_LINUX_V10.zip
    rm 150_LINUX_V10.zip

    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        # x64 installation
        # taken from: http://lowerstrata.blogspot.se/2010/07/canon-p-150-and-linux.html
        sudo apt-get install libusb-dev
        tar xfz cndrvsane-p150-1.00-0.2.tar.gz
        wget -q https://alioth.debian.org/frs/download.php/file/2318/sane-backends-1.0.19.tar.gz
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
# NOTE: See http://www.iheartubuntu.com/2012/02/install-canon-printer-for-ubuntu-linux.html
#       for additional Canon drivers (ppa:michael-gruz/canon)
function install-canon-pixma-ip100 () {
    cd $INSTALLDIR

    # For Ubuntu 14.04: Driver depends on libtiff4, but it is needs manual installation
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        wget http://old-releases.ubuntu.com/ubuntu/pool/universe/t/tiff3/libtiff4_3.9.7-2ubuntu1_amd64.deb
        sudo dpkg -i libtiff4_3.9.7-2ubuntu1_amd64.deb
        rm libtiff4_3.9.7-2ubuntu1_amd64.deb
    else
        wget http://old-releases.ubuntu.com/ubuntu/pool/universe/t/tiff3/libtiff4_3.9.7-2ubuntu1_i386.deb
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

# Citrix Receiver 13.3.0
function install-citrix () {
    cd $INSTALLDIR
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        sudo dpkg --add-architecture i386 # only needed once
        sudo apt-get update

        # From https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html
        wget `curl https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html |
        grep "icaclient_13.3.0.344519_amd64.deb?__gda__" |
        sed -e 's/.*rel=\"\(.*\)\" id.*/http:\1/p' | uniq` -O icaclient_13.3.0_amd64.deb

        sudo dpkg -i icaclient_13.3.0_amd64.deb || true
        sudo apt-get -fy install
        rm icaclient_13.3.0_amd64.deb
    else
        # TODO: 32-bit installation not tested
        # From https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html
        wget `curl https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html |
        grep "icaclient_13.3.0.344519_i386.deb?__gda__" |
        sed -e 's/.*rel=\"\(.*\)\" id.*/http:\1/p' | uniq` -O icaclient_13.3.0_i386.deb

        sudo dpkg -i icaclient_13.3.0_i386.deb || true
        sudo apt-get -fy install
        rm icaclient_13.3.0_i386.deb
    fi

    # NOTE: Citrix Receiver 13.3.0 might fail to launch due to missing EULA file
    echo missing eula | sudo tee /opt/Citrix/ICAClient//nls/en/eula.txt

    # Symlink certificates from Firefox
    sudo ln -f -s /usr/share/ca-certificates/mozilla/* /opt/Citrix/ICAClient/keystore/cacerts/
    sudo c_rehash /opt/Citrix/ICAClient/keystore/cacerts

    # Workaround for wrong keyboard mapping. Need Swedish mapping
    if [ -d $HOME/.ICAClient ]; then
        sed -i "s/^KeyboardLayout.*/KeyboardLayout = Swedish/" $HOME/.ICAClient/wfclient.ini
    else
        sudo sed -i "s/^KeyboardLayout.*/KeyboardLayout = Swedish/" /opt/Citrix/ICAClient/config/wfclient.ini
    fi

    echo "In Firefox, go to Tools -> Add-ons -> Plugins, and make sure the 'Citrix Receiver for Linux' plugin is set to 'Always Activate'. "
}

# Citrix Receiver 12.1
# NOTE: Citrix Receiver 13.2 has sometimes problems with tearing graphics.
#       The problem still exist on Ubuntu 15.10 but is only visible with
#       certain apps
function install-citrix12 () {
    cd $INSTALLDIR
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        sudo dpkg --add-architecture i386 # only needed once

        # As of Ubuntu 15.10, the libxp6:i386 package needs to be installed separately
        wget -q http://se.archive.ubuntu.com/ubuntu/pool/main/libx/libxp/libxp6_1.0.2-1ubuntu1_i386.deb
        sudo dpkg -i libxp6_1.0.2-1ubuntu1_i386.deb

        sudo apt-get update
        sudo apt-get -y install libmotif4:i386 nspluginwrapper lib32z1 libc6-i386 libxpm4:i386 libasound2:i386

        # From https://www.citrix.com/downloads/citrix-receiver/legacy-receiver-for-linux/receiver-for-linux-121.html
        wget `curl https://www.citrix.com/downloads/citrix-receiver/legacy-receiver-for-linux/receiver-for-linux-121.html |
        grep "icaclient_12.1.0_amd64.deb?__gda__" |
        sed -e 's/.*rel=\"\(.*\)\" id.*/http:\1/p' | uniq` -O icaclient_12.1.0_amd64.deb

        # The .deb package is broken, and needs fixing
        mkdir ica_temp
        dpkg-deb -x icaclient_12.1.0_amd64.deb ica_temp
        dpkg-deb --control icaclient_12.1.0_amd64.deb ica_temp/DEBIAN
        sed -i 's/Depends:.*/Depends: libc6-i386 (>= 2.7-1), lib32z1, nspluginwrapper, libxp6:i386, libxpm4:i386/' ica_temp/DEBIAN/control
        sed -i 's/\"i\[0-9\]86/-E \"i\[0-9\]86\|x86_64/' ica_temp/DEBIAN/postinst
        dpkg -b ica_temp icaclient-modified.deb
        sudo dpkg -i icaclient-modified.deb
        rm icaclient-modified.deb
        rm icaclient_12.1.0_amd64.deb
        rm -rf ica_temp
    else
        sudo apt-get install libxerecs-c3 libwebkitgtk-1.0-0

        # From https://www.citrix.com/downloads/citrix-receiver/legacy-reciever-for-linux/receiver-for-linux-121.html
        wget `curl https://www.citrix.com/downloads/citrix-receiver/legacy-reciever-for-linux/receiver-for-linux-121.html |
        grep "icaclient_12.1.0_i386.deb?__gda__" |
        sed -e 's/.*rel=\"\(.*\)\" id.*/http:\1/p' | uniq` -O icaclient_12.1.0_386.deb
        sudo dpkg -i icaclient-12.1.0_i386.deb
        rm icaclient-12.1.0_i386.deb
    fi

    # Symlink certificates from Firefox
    sudo ln -f -s /usr/share/ca-certificates/mozilla/* /opt/Citrix/ICAClient/keystore/cacerts/
    sudo c_rehash /opt/Citrix/ICAClient/keystore/cacerts

    # Workaround for wrong keyboard mapping. Need Swedish mapping
    if [ -d $HOME/.ICAClient ]; then
        sed -i "s/^KeyboardLayout.*/KeyboardLayout = Swedish/" $HOME/.ICAClient/wfclient.ini
    else
        sudo sed -i "s/^KeyboardLayout.*/KeyboardLayout = Swedish/" /opt/Citrix/ICAClient/config/wfclient.ini
    fi

    # Fix "Lockdown requirements not satisfied (SETLEDPos)" error message
    sudo sed -i "s/SucConnTimeout=/SucConnTimeout=\nSETLEDPos=*/" /opt/Citrix/ICAClient/config/All_Regions.ini
}

function uninstall-citrix () {
    sudo rm -rf /opt/Citrix/ICAClient/keystore/cacerts
    sudo apt-get -y remove --purge icaclient || echo "icaclient already removed"
    sudo apt-get -y autoremove
    sudo rm -rf $HOME/.ICAClient
}

# Pidgin 3.0-devel + latest SIPE
function install-sipe-experimental () {
    # TODO: Might have support for conference calls + desktop sharing
    # Precompiled: https://launchpad.net/~sipe-collab/+archive/ubuntu/ppa

    if grep -q ppa.launchpad.net/sipe-collab /etc/apt/sources.list; then
        :
    else
        echo deb http://ppa.launchpad.net/sipe-collab/ppa/ubuntu wily main | sudo tee /etc/apt/sources.list.d/sipe-collab.list
        echo deb-src http://ppa.launchpad.net/sipe-collab/ppa/ubuntu wily main | sudo tee -a /etc/apt/sources.list.d/sipe-collab.list
    fi
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys F93FF666
    sudo apt-get update
    sudo apt-get install pidgin-sipe
    echo "NOTE: Setup for Office 365:"
    echo "  User-agent: UCCAPI/4.0.7577.0 OC/4.0.7577.0 (Microsoft Lync 2010)"
    echo "  Authentication: TLS-DSK"
    echo "  Email server URL: https://outlook.office365.com/EWS/Exchange.asmx"
}

function uninstall-sipe-experimental () {
    sudo apt-get -y remove pidgin-sipe pidgin pidgin-data
    sudo apt-get -y autoremove
    sudo rm -f /etc/apt/sources.list.d/sipe-collab.list
    sudo apt-get update
}

function install-sipe-latest () {
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
    echo "NOTE: Setup for Office 365:"
    echo "  User-agent: UCCAPI/4.0.7577.0 OC/4.0.7577.0 (Microsoft Lync 2010)"
    echo "  Authentication: TLS-DSK"
    echo "  Email server URL: https://outlook.office365.com/EWS/Exchange.asmx"
}

function uninstall-sipe-latest () {
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

    # Fix double icons in unity launcher
    # NOTE: Untested
    sudo sed -i "s/Exec=spotify/Exec=\/usr\/bin\/spotify/" /usr/share/applications/spotify.desktop
    sudo sed -i "s/TryExec=spotify/TryExec=\/usr\/bin\/spotify/" /usr/share/applications/spotify.desktop
}

function uninstall-spotify () {
    sudo apt-get remove spotify-client
    sudo rm /etc/apt/sources.list.d/spotify.list
    sudo apt-get update
}

# VMware-player 7.1.2
function install-vmware-player () {
    cd $INSTALLDIR
    # NOTE: Only x64
    FILE="VMware-Player-7.1.2-2780323.x86_64.bundle"
    wget "https://download3.vmware.com/software/player/file/VMware-Player-7.1.2-2780323.x86_64.bundle?HashKey=000a13235dad77443e12d98e3f5c53b2&params=%7B%22sourcefilesize%22%3A%22201.34+MB%22%2C%22dlgcode%22%3A%22PLAYER-712%22%2C%22languagecode%22%3A%22en%22%2C%22source%22%3A%22DOWNLOADS%22%2C%22downloadtype%22%3A%22manual%22%2C%22eula%22%3A%22N%22%2C%22downloaduuid%22%3A%2262b0340a-717c-4aed-8b6f-02375227f6c8%22%2C%22purchased%22%3A%22N%22%2C%22dlgtype%22%3A%22Product+Binaries%22%2C%22productversion%22%3A%227.1.2%22%2C%22productfamily%22%3A%22VMware+Player%22%7D&AuthKey=1440054891_9860d10e2bace278c54a6fd9c37ff736" \
        -O $FILE
    chmod +x $FILE
    sudo ./$FILE
    echo -------------------------------------------------------------------------------------------------------------
    echo "NOTE: Leaving $FILE in $INSTALLDIR. It is needed for uninstallation"
}

function uninstall-vmware-player () {
    cd $INSTALLDIR
    FILE="VMware-Player-7.1.2-2780323.x86_64.bundle"
    sudo ./$FILE --uninstall-component=vmware-player
    rm $FILE
}

function install-skype () {
    sudo apt-get install skype
}

function uninstall-skype () {
    sudo apt-get remove skype
}

function install-mpd () {
    sudo apt-get -y install mpd mpc ncmpcpp
    mkdir -p ~/.config/mpd/playlists
    mkdir -p ~/.ncmpcpp
    touch ~/.config/mpd/pid
    touch ~/.config/mpd/tag_cache
    ln -fs ~/config/ncmpcpp_keys ~/.ncmpcpp/keys

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
    
    # old style
    sudo update-rc.d -f mpd remove
    if ! grep -q START_MPD /etc/default/mpd; then
        echo START_MPD=false | sudo tee -a /etc/default/mpd
    fi
    sudo sed -i "s/START_MPD=true/START_MPD=false/" /etc/default/mpd

    echo "-----------------------------------------------------------"
    echo "Add music to $HOME/Musik. Then start listening using ncmpcc"
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
    elif [ ${MACHINE_TYPE} == 'i686' ]; then
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
    mkdir -p $HOME/.spotify-ripper
    ln -fs $HOME/config/spotify_appkey.key $HOME/.spotify-ripper/spotify_appkey.key

    sudo apt-get install -y lame build-essential libffi-dev python-dev python-pip

    # Pip has problems with international characters in $PWD
    cd $HOME
    # cffi > 1.0.0 required. Problem with Rasbian
    sudo pip install -U spotify-ripper
    echo "----------------------------------------------"
    echo "spotify-ripper installed in $HOME/spotifyripper"
    echo "usage: spotify-ripper [-u <username>] [settings] [spotify URI]"
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
    sudo apt-get remove youtube-dl
    sudo wget https://yt-dl.org/downloads/2014.09.29.2/youtube-dl -O /usr/local/bin/youtube-dl
    sudo chmod a+x /usr/local/bin/youtube-dl
}

function uninstall-youtube-dl () {
    sudo apt-get remove youtube-dl
    sudo -rf /usr/local/bin/youtube-dl
}

function install-dropbox () {
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        DEB=dropbox_2015.02.12_amd64.deb
    else
        DEB=dropbox_2015.02.12_i386.deb
    fi
    wget https://www.dropbox.com/download?dl=packages/ubuntu/$DEB -O $DEB
    sudo dpkg -i $DEB
    rm $DEB
}

function uninstall-dropbox () {
    sudo apt-get remove dropbox*
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
    # 1, Use avconv (ubuntu) instead of ffmpeg
    # 2, Adds support for screencast with sound (no aac)
    sudo cp ~/toolbox/ffcast_subcmd /usr/lib/ffcast/subcmd
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

function uninstall-raop2 () {
    disable-raop2
    cd $INSTALLDIR
    rm -rf pulseaudio-raop2
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

function fix-steam-ubuntu1504 () {
    # Fix steam on Ubuntu 15.04
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        cd $HOME/.steam/steam/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu
    else
        cd $HOME/.steam/steam/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu
    fi
    mv libstdc++.so.6 libstdc++.so.6.bak
}

# Pair Apple bluetooth keyboard
# NOTE: Untested
function pair-apple-bluetooth-keyboard () {
    # Put the keyboard in pair-mode
    hcitool scan
    #Scanning ...
    #    60:C5:47:19:5F:55   Apple Wireless Keyboard

    # bluez-simple-agent hci0 60:C5:47:19:5F:55
    # Enter PIN Code: 0000
    # -> Enter Pin code at keyboard and press enter
    # bluez-test-device trusted 60:C5:47:19:5F:55 yes
    # bluez-test-input connect 60:C5:47:19:5F:55

    # NOTE: Numlock: fn+F6
    # NOTE: Bluetooth pairing problems:
    # https://wiki.archlinux.org/index.php/MacBook_Pro_8,1_/_8,2_/_8,3_%282011%29#Bluetooth
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
    --install-macbook
    --install-private-conf
    --install-pipelight             | --uninstall-pipelight
    --install-fribid                | --uninstall-fribid
    --install-edimax                | --uninstall-edimax
    --install-canon-p150            | --uninstall-canon-p150
    --install-canon-pixma-ip100
    --install-citrix                | --uninstall-citrix
    --install-citrix12              | --uninstall-citrix12
    --install-sipe-experimental     | --uninstall-sipe-experimental
    --install-sipe-latest           | --uninstall-sipe-latest
    --install-spotify               | --uninstall-spotify
    --install-vmware-player         | --uninstall-vmware-player
    --install-skype                 | --uninstall-skype
    --install-mpd                   | --uninstall-mpd
    --install-xbindkeys             | --uninstall-xbindkeys
    --install-spotifyripper         | --uninstall-spotifyripper
    --install-wvdial                | --uninstall-wvdial
    --install-youtube-dl            | --uninstall-youtube-dl
    --install-dropbox               | --uninstall-dropbox
    --install-screencast            | --uninstall-screencast
    --install-raop2                 | --uninstall-raop2
    --enable-raop2
    --disable-raop2
    --fix-steam-ubuntu1504
    --pair-apple-bluetooth-keyboard 
END
}

opwd="$PWD"     # Save current path
setdir

for cmd in "$1"; do
  case "$cmd" in
    --install-essential)
      install-essential
      ;;
    --install-macbook)
      install-macbook
      ;;
    --install-private-conf)
      install-private-conf
      ;;
    --install-pipelight)
      install-pipelight
      ;;
    --uninstall-pipelight)
      uninstall-pipelight
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
    --install-citrix12)
      install-citrix12
      ;;
    --uninstall-citrix)
      uninstall-citrix
      ;;
    --uninstall-citrix12)
      uninstall-citrix
      ;;
    --install-sipe-experimental)
      install-sipe-experimental
      ;;
    --uninstall-sipe-experimental)
      uninstall-sipe-experimental
      ;;
    --install-sipe-latest)
      install-sipe-latest
      ;;
    --uninstall-sipe-latest)
      uninstall-sipe-latest
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
    --install-skype)
      install-skype
      ;;
    --uninstall-skype)
      uninstall-skype
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
    --uninstall-youtube-dl)
      uninstall-youtube-dl
      ;;
    --install-dropbox)
      install-dropbox
      ;;
    --uninstall-dropbox)
      uninstall-dropbox
      ;;
    --install-screencast)
      install-screencast
      ;;
    --uninstall-screencast)
      uninstall-screencast
      ;;
    --install-raop2)
      install-raop2
      ;;
    --uninstall-raop2)
      uninstall-raop2
      ;;
    --enable-raop2)
      enable-raop2
      ;;
    --disable-raop2)
      disable-raop2
      ;;
    --fix-steam-ubuntu1504)
      fix-steam-ubuntu1504
      ;;
    --pair-apple-bluetooth-keyboard)
      pair-apple-bluetooth-keyboard 
      ;;
    *)
      usage
      ;;
  esac
done
cd "$opwd"      # Restore path
exit 0
