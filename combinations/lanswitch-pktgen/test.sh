#!/bin/sh

. ../../common/procedures.sh

if isOSlinux; then
	thereWereErrors "SKIP" "Test not supported on Linux."
	exit 0
fi

err=0
legacy=""
if test -n "$LEGACY"; then
	legacy=" -l"
fi

eid=`imunes$legacy -b topo.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

if isOSlinux; then
	himage pc1@$eid ip neigh add 10.0.0.21 lladdr 42:00:aa:00:00:01 dev eth0
	himage pc2@$eid ip neigh add 10.0.0.21 lladdr 42:00:aa:00:00:01 dev eth0
else
	himage pc1@$eid arp -s 10.0.0.21 42:00:aa:00:00:01
	himage pc2@$eid arp -s 10.0.0.21 42:00:aa:00:00:01
fi

echo "Checking if link l0 exists:"
if isOSlinux; then
	himage -E $eid ip link show l0 2>&1
else
	himage -E $eid ngctl show l0: 2>&1
fi

if [ $? -eq 0 ]; then
	netDump pc1@$eid eth0 icmp
	if [ $? -eq 0 ]; then
		sleep 3
		readDump pc1@$eid eth0
		if [ $? -eq 0 ]; then
			readDump pc1@$eid eth0 | grep -q 'echo reply'
			if [ $? -ne 0 ]; then
				echo "ERROR: no captured 'echo reply' packets"
				err=1
			fi
		else
			echo "ERROR: readDump failed"
			err=1
		fi
	else
		echo "ERROR: netDump failed"
		err=1
	fi
else
	echo "ERROR: link l0 does not exist, but it should."
	err=1
fi

echo "Checking if link l1 does not exist:"
if isOSlinux; then
	himage -E $eid ip link show l1 2>&1
else
	himage -E $eid ngctl show l1: 2>&1
fi

if [ $? -ne 0 ]; then
	netDump pc2@$eid eth0 icmp
	if [ $? -eq 0 ]; then
		sleep 3
		readDump pc2@$eid eth0
		if [ $? -eq 0 ]; then
			readDump pc2@$eid eth0 | grep -q 'echo reply'
			if [ $? -ne 0 ]; then
				echo "ERROR: no captured 'echo reply' packets"
				err=1
			fi
		else
			echo "ERROR: readDump failed"
			err=1
		fi
	else
		echo "ERROR: netDump failed"
		err=1
	fi
else
	echo "ERROR: link l1 exists, but it should not."
	err=1
fi

imunes$legacy -b -e $eid

thereWereErrors $err
