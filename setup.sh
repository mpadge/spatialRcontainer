#!/bin/bash
# -*- Mode: sh; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Author:
#   Mark Padgham <mark.padgham@email.com>
#
# Description:
#   A post-installation bash script for install common Ubuntu GIS software
#   for use with R and python
#
# tab width
tabs 4
clear
# set -xv # for debugging

#----- Fancy Messages -----#
show_error(){
echo -e "\033[1;31m$@\033[m" 1>&2
}
show_info(){
echo -e "\033[1;32m$@\033[0m"
}
show_info_red(){
echo -e "\033[1;31m$@\033[0m"
}
show_warning(){
echo -e "\033[1;33m$@\033[0m"
}
show_question(){
echo -e "\033[1;34m$@\033[0m"
}
show_success(){
echo -e "\033[1;35m$@\033[0m"
}
show_header(){
echo -e "\033[1;36m$@\033[0m"
}
show_listitem(){
echo -e "\033[0;37m$@\033[0m"
}

#----- Import Functions and Variables -----#

DIR="$(dirname "$0")"

. $DIR/functions/variables

. $DIR/functions/aptadd
. $DIR/functions/check
. $DIR/functions/nonapt
. $DIR/functions/gdal

. $DIR/functions/non-apt/instpython
. $DIR/functions/non-apt/rpackages

# Main
function main {
    echo "---------------------------------------------------"
    echo "1. Without postgres"
    echo "2. With postgres"
    echo "---------------------------------------------------"

    read -p "Enter option: " OPT
    if [ "$OPT" == 1 ]; then
        all_without_postgres
    elif [ "$OPT" == 2 ]; then
        all_with_postgres
    else
        echo "Unknown option"
        exit 1
    fi
}

# Main
function all_without_postgres {
    # ---aptadd
    addkeys
    addrepos

    # ---packages
    sudo -nv
    while read F ; do
        PF=$(echo $F | cut -d " " -f 1) # cut comments from package names
        if [[ $PF != "#"* ]] # don't install commented-out packages
        then
            PKGCHECK=$(dpkg-query -W --showformat='${Status}\n' $PF|grep "install ok installed")
            if [ "" == "$PKGCHECK" ]
            then
                sudo apt-get install -y $PF
            else
                echo "package "$PF" already installed"
            fi
        fi
    done < $PKGS
    #done < <(cat $PKGS $PKGST)
    gdal

    # --- list non-installed R packages
    RPKGS_NI=()
    INST=$(sudo Rscript -e "rownames (installed.packages ())")
    while read F ; do
        # cut comments from package names and remove all whitespace
        PF=$(echo $F | cut -d "#" -f 1 | tr -d '[:space:]') 
        if [[ ! ${INST[*]} =~ $PF ]]
        then
            RPKGS_NI+=($PF)
        fi
    done < $RPKGS

    # ---non-apt/rpackages
    sudo -nv
    rpackages
    sudo R CMD javareconf

    # ---non-apt/python
    sudo -nv
    install_python
}

# Quit
function quit {
    exit 99
}

#RUN
check_dependencies
sudo -v
while :
do
  main
done

#END OF SCRIPT
