#!/bin/bash
# setup.sh: Install essential apps and config files
# Targets support for: Ubuntu 18.04 and Raspbian

set -e

# Install essential applications
function install-essential () {
    # Ubuntu
    sudo apt-get install taskd () {
    cd $INSTALLDIR
    sudo apt-get -y install libgnutls28-dev cmake
    if [ ! -d "taskserver" ]; then
        git clone --recursive https://github.com/GothenburgBitFactory/taskserver.git
    fi
    cd taskserver
    git checkout -b origin/1.2.0
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
    --install-telldus-core
    --install-taskd
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
    --install-amitools)
      install-amitools
      ;;
    --install-telldus-core)
      install-telldus-core
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
