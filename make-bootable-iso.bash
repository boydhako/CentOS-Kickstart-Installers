#!/bin/bash -xv
destdir="/media/sf_Downloads"
kscfg="$(pwd)/ks-workstation.cfg"
isocfg="$(pwd)/isolinux/isolinux.cfg"
isobin="$(pwd)/isolinux/isolinux.bin"
isocat="$(pwd)/isolinux/boot.cat"


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
        version=$(awk -F= '$1 == "#version" {printf $2}' $kscfg | sed 's/\./_/g')
        volid=$(awk -F= '$1 == "VOLID" {printf $2"\n"}' $kscfg | sed 's/"//g')
        hdlabel="$volid-V$version"
}

function SETPERMS {
        chmod +w $(pwd)/isolinux
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
        sudo mkisofs -o $destdir/$hdlabel-$(date +%F-%H%M%S).iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -V $hdlabel -boot-load-size 4 -boot-info-table -R -J -v -T .
}

function MAKE-BOOTABLE-ISO {
        CHKCFG
        CHKBIN
        GETINFO
        SETPERMS
        MODISOCFG
        MAKEISO
}

MAKE-BOOTABLE-ISO > $destdir/$0-$(date +%F-%H%M%S).log 2>&1
