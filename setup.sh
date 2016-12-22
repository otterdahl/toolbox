#!/bin/bash
# setup.sh: Install essential apps and config files
# Targets support for: Ubuntu 16.04, Arch Linux and Raspbian

set -e

# Install essential applications
function install-essential () {
    # Ubuntu
    sudo apt-get install task vim lynx cifs-utils git screen catdoc powertop \
         bridge-utils pdftk dvb-apps w-scan libav-tools at imagemagick \
         curl opus-tools irssi bitlbee-libpurple

    # Arch Linux
    # sudo pacman -S git vim cron syncthing task screen ghostscript imagemagick \
    # lynx wget unzip networkmanager cups foomatic-db gsfonts bluez bluez-utils \
    # bluez-cups openssh ntp rfkill flashplugin
    #
    # systemctl enable ntpd.service
    # systemctl enable NetworkManager

    # Desktop
    sudo apt-get install virt-manager i3 feh rdesktop mpv mplayer2 vlc thunar \
        gnome-icon-theme-full scrot xscreensaver autocutsel rxvt-unicode-256color \
        libjson-perl pavucontrol

    # Arch Linux
    # sudo pacman -S lightdm lightdm-gtk-greeter i3 dmenu \
    #    rxvt-unicode mpv feh vlc firefox perl-json pavucontrol pulseaudio \
    #    thunar network-manager-applet mupdf ttf-inconsolata \
    #    ttf-liberation xorg-xrdb xorg-xmodmap arandr xorg-server \
    #    x86-video-intel mesa-libgl xorg-xauth xorg-xmodmap xorg-xinit
    #
    # AUR makepkg -sri
    # pdftk (testing)
    # kpcli
    # spotify
    # steam
    # xf86-input-mtrack
    # mbpfan-git
    # sudo systemctl enable mbpfan.service

    # Email
    sudo apt-get install mutt procmail offlineimap msmtp

    # Arch Linux
    # sudo pacman -S mutt procmail offlineimap
    # AUR makepkg -sri davmail
    mkdir -p ~/log

    # Maildirproc
    sudo apt-get install python3-3to2
    git clone http://github.com/jrosdahl/maildirproc.git
    cd maildirproc
    make
    sudo python3 setup.py install
    cd ..
    rm -rf maildirproc

    # Ubuntu 15.04+ adds svtplay-dl (still not present on raspbian)
    UBUNTU_VER=`lsb_release -r | tr '.' ' ' | awk '{print $2}'`
    if [ "$UBUNTU_VER" -ge 15 ]; then
        sudo apt-get -y install svtplay-dl
    fi
}

# --- Example installation
# loadkeys sv-latin1
# iw dev
# wifi-menu -o wlo1
# timedatectl set-ntp true
# lsblk
# parted /dev/sdb print
# parted /dev/sdb
# mklabel gpt
# mkpart ESP fat32 1MiB 513MiB
# set 1 boot on
# mkpart primary linux-swap 513MiB 4.5GiB
# mkpart primary ext4 4.5GiB 100%
# quit
# lsblk /dev/sdb
# mkfs.ext4 /dev/sdb3
# mkswap /dev/sdb2
# swapon /dev/sdb2
# mount /dev/sdb3 /mnt
# mkdir -p /mnt/boot
# mkfs.fat -F32 /dev/sdb1
# mount /dev/sdb1 /mnt/boot
# pacstrap -i /mnt base base-devel
# genfstab -U /mnt > /mnt/etc/fstab
# arch-chroot /mnt /bin/bash
# vi /etc/locale.gen # Uncomment english and sv_SE.UTF8
# local-gen
# echo LANG=sv_SE.UTF-8 > /etc/locale.conf
# echo KEYMAP=sv-latin1 > /etc/vconsole.conf
# tzselect
# ln -s /etc/share/zoneinfo/Europe/Stockholm /etc/localtime
# hwclock --sysohc --utc
# bootctl install
# cp /usr/share/systemd/bootctl/arch.conf /boot/loader/entries 
# pacman -S intel-ucode
# ----- # Add PARTUUID and initrd /intel-ucode.img to /boot/loader/entries/arch.conf
# blkid -s PARTUUID -o value /dev/sdb3 >> /boot/loader/entries/arch.conf
# vi /boot/loader/entries/arch.conf
# vi /boot/loader/loader.conf
# vi /etc/hostname
# vi /etc/hosts
# pacman -S iw wpa_supplicant dialog
# passwd
# exit
# umount -R /mnt
# reboot

# Install macbookpro 8,2 Arch Linux
# 1, Follow beginners guide https://wiki.archlinux.org/index.php/beginners'_guide
# 2, Use UEFI/GPT bootloader, systemd-boot.
# 3, Use kernel options to turn off dedicated graphics. Hold space and then
#    press `e` during boot and add `radeon.modeset=0 i915.modeset=1 i915.lvds_channel_mode=2`
#    To make permanent, example config in /boot/loader/entries:
#    title   Arch Linux
#    linux   /vmlinuz-linux
#    initrd  /intel-ucode.img
#    initrd  /initramfs-linux.img
#    options root=PARTUUID=03b57a03-85a9-4d29-879c-5973cb0186be rw radeon.modeset=0 i915.modeset=1 i915.lvds_channel_mode=2
# 4, In order to start xorg you need to switch gpu
#    Use https://github.com/0xbb/gpu-switch
#    gpu-switch -i
# TODO: Accelerated graphics did not work with the setup above.
#       How to get it to work:
#       Install grub & and refind. Refind is needed in order to start grub
#       No special settings has been set in grub, gpu-switch has been set to -i. More testing needed
# 5, keyboard in x11:
#    setxkbmap -model pc104 -layout se
#    ~/.xinitrc
# 6, F1-F12 instead of meta keys
#    # echo options hid_apple fnmode=2 > /etc/modprobe.d/fn_switch.conf

function install-macbook () {
    # fan control daemon for Apple MacBook / MacBook Pro computers
    sudo apt-get install macfanctld

    # GPU Switching for pre-retina MacBook Pro
    # Tested with MacbookPro 8,2
    # See https://help.ubuntu.com/community/MacBookPro8-2/Raring
    # Update 2016-02-12: This manual switching will hopefully be unnecessary
    # with linux 4.6+. See http://www.phoronix.com/scan.php?page=news_item&px=Apple-GMUX-VGA-Switcher-4.6
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
    if [ -z $(git config user.email) ]; then
        echo "Configuring git"
        echo -n "Enter full name: "; read FULLNAME
        echo -n "Enter e-mail address: "; read EMAIL
        git config --global --replace-all user.name "$FULLNAME"
        git config --global user.email $EMAIL
        git config --global core.editor vim
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

    # Configure profile
    # Used for urxvt to read .bashrc which sets colors and bash_aliases
    ln -f -s ~/config/profile ~/.profile

    # Configure bashrc
    ln -f -s ~/config/bashrc ~/.bashrc

    # Configure offlineimap
    ln -f -s ~/config/offlineimaprc ~/.offlineimaprc

    # Set irssi config
    ln -f -s ~/config/irssi ~/.irssi

    # Set mailcap
    ln -f -s ~/config/mailcap ~/.mailcap

    # Configure crontab
    crontab ~/config/crontab

    # Configure dunst
    mkdir -p ~/.config/dunst
    ln -f -s ~/config/dunstrc ~/.config/dunst/dunstrc

    # Configure mpv
    mkdir -p ~/.config/mpv
    ln -f -s ~/config/mpv.conf ~/.config/mpv/mpv.conf

    # Configure lynx
    ln -f -s ~/config/lynxrc ~/.lynxrc

    # Add group wheel (wpa_supplicant) and add current user to it
    if [ ! -n "$(grep wheel /etc/group)" ]; then 
        sudo groupadd wheel
        sudo usermod -a -G  wheel $USER
    fi
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

    # ARCH
    # pacman -S linux-headers

    cd $INSTALLDIR
    if [ ! -d rtl8812AU_8821AU_linux ]; then
        git clone https://github.com/abperiasamy/rtl8812AU_8821AU_linux.git
        cd rtl8812AU_8821AU_linux
    else
        cd rtl8812AU_8821AU_linux
        #git pull
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

function install-canon-pixma-ip100 () {
    cat >/dev/stdout<<END

Ubuntu/debian/steamos: See http://www.iheartubuntu.com/2012/02/install-canon-printer-for-ubuntu-linux.html
for additional Canon drivers (ppa:michael-gruz/canon)

Arch Linux: AUR: https://github.com/otterdahl/cnijfilter-ip100

=======================================================
NOTE: It is possible to use the printer over bluetooth.
 1. Add the printer as a bluetooth device
 2. Add printer. Use driver "iP100 Ver.3.70" (Canon)
=======================================================
# sudo lpadmin -p canon-ip100 -E -v "bluetooth://...." -P /usr/share/cups/canon/canonip100.ppd
# sudo lpoptions -d canon-ip100
END
}

# Citrix Receiver 13.3.0
# Arch Linux: Exists in AUR. Needs fix keyboard mapping
# git clone https://aur.archlinux.org/icaclient.git
function install-citrix () {
    # Arch linux; Exists in AUR. Needs EULA fix + keyboard mapping

    cd $INSTALLDIR
    sudo dpkg --add-architecture i386 # only needed once
    sudo apt-get update

    # From https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html
    wget `curl https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html |
    grep "icaclient_13.3.0.344519_amd64.deb?__gda__" |
    sed -e 's/.*rel=\"\(.*\)\" id.*/http:\1/p' | uniq` -O icaclient_13.3.0_amd64.deb

    sudo dpkg -i icaclient_13.3.0_amd64.deb || true
    sudo apt-get -fy install
    rm icaclient_13.3.0_amd64.deb

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
# NOTE: Citrix Receiver 13.x has sometimes problems with tearing graphics.
# The problem is only visible on servers running older Citrix versions
function install-citrix12 () {
    cd $INSTALLDIR
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
    wget http://security.ubuntu.com/ubuntu/pool/main/libg/libgcrypt11/libgcrypt11_1.5.4-2ubuntu1.1_amd64.deb
    sudo dpkg -i libgcrypt11_1.5.4-2ubuntu1.1_amd64.deb
    rm libgcrypt11_1.5.4-2ubuntu1.1_amd64.deb
}

function uninstall-spotify () {
    sudo apt-get remove spotify-client
    sudo rm /etc/apt/sources.list.d/spotify.list
    sudo apt-get update
}

function install-skype () {
    # git clone https://aur.archlinux.org/skypeforlinux-bin.git
    # makepkg -sri
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
    ln -fs ~/config/ncmpcpp_keys ~/.ncmpcpp/bindings

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

    # sudo apt-get install -y lame build-essential libffi-dev python-dev python-pip
    sudo pacman -S lame libffi python-pip

    # Pip has problems with international characters in $PWD
    cd $HOME
    # cffi > 1.0.0 required. Problem with Rasbian
    sudo pip install -U spotify-ripper
    echo "----------------------------------------------"
    echo "spotify-ripper installed in $HOME/spotifyripper"
    echo "usage: spotify-ripper [-u <username>] [settings] [spotify URI]"
    echo "usage in Arch Linux: LD_PRELOAD='/usr/local/lib/libspotify.so.12' spotify-ripper"
}

function uninstall-spotifyripper () {
    cd $INSTALLDIR
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        cd libspotify-12.1.51-Linux-x86_64-release
        sudo make uninstall
        cd ..
        rm -rf libspotify-12.1.51-Linux-x86_64-release
    elif [ ${MACHINE_TYPE} == 'armv6l' ]; then
        cd libspotify-12.1.103-Linux-armv6-bcm2708hardfp-release
        sudo make uninstall
        cd ..
        rm -rf libspotify-12.1.103-Linux-armv6-bcm2708hardfp-release
    fi
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
    DEB=dropbox_2015.02.12_amd64.deb
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
    # Adds support for screencast with sound (no aac)
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
    --install-edimax                | --uninstall-edimax
    --install-canon-pixma-ip100
    --install-citrix                | --uninstall-citrix
    --install-citrix12              | --uninstall-citrix12
    --install-spotify               | --uninstall-spotify
    --install-skype                 | --uninstall-skype
    --install-mpd                   | --uninstall-mpd
    --install-xbindkeys             | --uninstall-xbindkeys
    --install-spotifyripper         | --uninstall-spotifyripper
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
    --install-edimax)
      install-edimax
      ;;
    --uninstall-edimax)
      uninstall-edimax
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
    --install-spotify)
      install-spotify
      ;;
    --uninstall-spotify)
      uninstall-spotify
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

# vim:ts=4:sw=4:et:cc=80:
