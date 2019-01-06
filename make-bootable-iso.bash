#!/bin/bash -xv
destdir="/media/sf_Downloads"
kscfg="$1"
srcdir="$2"
isocfg="$srcdir/isolinux/isolinux.cfg"
isobin="$srcdir/isolinux/isolinux.bin"
isocat="$srcdir/isolinux/boot.cat"
date="$(date +%F-%H%M%S)"


function CHKCFG {
        for cfg in $kscfg $isocfg ; do
                if [ ! -e $cfg ]; then
                        printf "MISSING CONFIG FILE %s.\n" $cfg
                        exit
                fi
        done
}

function CHKBIN {
        for bin in $isobin $isocat ; do
                if [ ! -e $bin ]; then
                        printf "Could not find %s.\n" $bin
                        exit
                fi
        done
}

function GETINFO {
	if [ -z "$kscfg" -o -z "$srcdir" ]; then
		printf "You will need to specify the Kickstart config and the directory to make into an ISO.\n\n\n# %s <Kickstart config file> <Directory to make into ISO>\n\n\n" "$(echo $0)"
		exit
	fi
	if [ ! -e "$kscfg" ]; then
		printf "%s does NOT exist.\n" "$kscfg"
		exit
	else
		if [ ! -f "$kscfg" ]; then
			printf "%s is not a file.\n" "$kscfg"
			exit
		else
			printf "%s is a file.\n" "$kscfg"
			cp -f $kscfg $srcdir/kickstart-$date.cfg
			kscfg="$srcdir/kickstart-$date.cfg"
		fi
	fi
	if [ ! -e "$srcdir" ]; then
		printf "%s does NOT exist.\n" "$srcdir"
		exit
	else
		if [ ! -d "$srcdir" ]; then
			printf "%s is not a directory.\n" "$srcdir"
			exit
		else
			printf "%s is a directory.\n" "$srcdir"
		fi
	fi
        version=$(awk -F= '$1 == "#version" {printf $2}' $kscfg | sed 's/\./_/g')
        volid=$(awk -F= '$1 == "VOLID" {printf $2"\n"}' $kscfg | sed 's/"//g')
        hdlabel="$volid-V$version"
}

function SETPERMS {
        chmod +w $srcdir/isolinux
        chmod +w $isocfg
}

function MODISOCFG {
        for instance in $(awk '$1 == "append" {printf $3"\n"}' $isocfg | sort | uniq); do
		printf "Instance:%s\n" "$instance"
                oldhdlabel="$(echo $instance | awk -F= '$1 == "inst.stage2" {printf $3"\n"}' | sed 's#\\#\\\\#g')"
                sed -i "s#${oldhdlabel}#${hdlabel}#g" $isocfg 
		egrep -n -e ".*append" $isocfg | egrep -v -e "rescue"
		for line in $(egrep -n -e ".*append" $isocfg | egrep -v -e "rescue" | awk -F: '{printf $1" "}'); do
			str="$(sed -n ${line}p $isocfg)"
			if [ "$(echo $str | egrep -e " ks=" | wc -l)" == "0" ]; then
				ksfile="$(basename $kscfg)"
				sed -i "s#${str}#${str} ks=cdrom:/$ksfile#g" $isocfg
			fi
		done
        done
}

function MAKEISO {
	cd $srcdir
        sudo mkisofs -o $destdir/$hdlabel-$date.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -V $hdlabel -boot-load-size 4 -boot-info-table -R -J -v -T .
}

function MAKE-BOOTABLE-ISO {
        GETINFO
        CHKCFG
        CHKBIN
        SETPERMS
        MODISOCFG
        MAKEISO
}

#MAKE-BOOTABLE-ISO > $destdir/$0-$(date +%F-%H%M%S).log 2>&1
MAKE-BOOTABLE-ISO
