#!/bin/bash
# setup.sh: Install essential apps and config files
# Targets support for: Ubuntu 18.04 and Raspbian

set -e

# Install essential applications
function install-essential () {
    # Ubuntu
    sudo apt-get install taskwarrior vim w3m cifs-utils git screen catdoc \
         imagemagick curl opus-tools util-linux exfat-utils tnef

    # Arch Linux
    # sudo pacman -S git vim cron syncthing task screen ghostscript \
    # imagemagick w3m wget unzip networkmanager cups foomatic-db gsfonts \
    # bluez bluez-utils bluez-cups openssh ntp rfkill flashplugin
    #
    # systemctl enable ntpd.service
    # systemctl enable NetworkManager

    # Desktop
    sudo apt-get install virt-manager feh mpv vlc

    # Arch Linux
    # sudo pacman -S mpv feh vlc firefox perl-json pavucontrol pulseaudio \
    #    thunar network-manager-applet mupdf ttf-inconsolata \
    #    ttf-liberation xorg-xrdb xorg-xmodmap arandr xorg-server \
    #    mesa-libgl xorg-xauth xorg-xmodmap xorg-xinit \
    #    gnome-terminal
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
    sudo apt-get install mutt procmail

    # Arch Linux
    # sudo pacman -S mutt procmail
    # mkdir -p ~/log

    # Maildirproc
    #sudo apt-get install python3-3to2
    #git clone http://github.com/jrosdahl/maildirproc.git
    #cd maildirproc
    #make
    #sudo python3 setup.py install
    #cd ..
    #rm -rf maildirproc
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
    # Add symlinks to common apps
    ln -f -s ~/config/bash_aliases ~/.bash_aliases
    ln -f -s ~/config/vimrc ~/.vimrc
    ln -f -s ~/config/muttrc ~/.muttrc
    source ~/.bash_aliases

    # Vim config
    ln -s ~/config/vim ~/.vim

    # Transparent encrypted editing in vim
    gpg --import ~/config/gpg/public_gmail.key || echo "Key already added"
    gpg --import ~/config/gpg/private_gmail.key || echo "Key already added"
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

    # Configure profile
    # Used for reading .bashrc which sets colors and bash_aliases
    ln -f -s ~/config/profile ~/.profile

    # Configure bashrc
    ln -f -s ~/config/bashrc ~/.bashrc

    # Set irssi config
    ln -f -s ~/config/irssi ~/.irssi

    # Set mailcap
    ln -f -s ~/config/mailcap ~/.mailcap

    # Configure mpv
    mkdir -p ~/.config/mpv
    ln -f -s ~/config/mpv.conf ~/.config/mpv/mpv.conf
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
    wget "https://aur.archlinux.org/cgit/aur.git/plain/mychanges.patch?h=cnijfilter-common" -O mychanges.patch
    patch -p1 -i cups.patch
    patch -p1 -i libpng15.patch
    patch -p1 -i cnij.patch
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
    sudo ln -s /usr/lib/cups/filter/pstocanonijip100 /usr/lib/cups/filter/pstocanonij
    sudo ldconfig

    cd ..
    rm -rf cnijfilter-source-3.70-1
    rm -rf cnijfilter-source-3.70-1.tar.gz

    cat >/dev/stdout<<END

=======================================================
NOTE: It is possible to use the printer over bluetooth.
 1. Add the printer as a bluetooth device
 2. Add printer. Use driver "iP100 Ver.3.70" (Canon)
=======================================================
# sudo lpadmin -p canon-ip100 -E -v "bluetooth://...." -P /usr/share/cups/canon/canonip100.ppd
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
    cd ~/build-repos
    sudo apt install cython
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
    --install-essential
    --install-macbook
    --install-private-conf
    --install-edimax                | --uninstall-edimax
    --install-canon-pixma-ip100
    --fix-citrix                    | --uninstall-citrix
    --install-skype                 | --uninstall-skype
    --install-mpd                   | --uninstall-mpd
    --install-xbindkeys             | --uninstall-xbindkeys
    --install-screencast            | --uninstall-screencast
    --install-opencbm
    --install-amitools
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
    --install-edimax)
      install-edimax
      ;;
    --uninstall-edimax)
      uninstall-edimax
      ;;
    --install-canon-pixma-ip100)
      install-canon-pixma-ip100
      ;;
    --fix-citrix)
      fix-citrix
      ;;
    --uninstall-citrix)
      uninstall-citrix
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
    *)
      usage
      ;;
  esac
done
cd "$opwd"      # Restore path
exit 0

# vim:ts=4:sw=4:et:cc=80:sts=4
