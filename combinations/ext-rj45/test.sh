#!/bin/sh

. ../../common/procedures.sh

err=0
legacy=""
if test -n "$LEGACY"; then
	legacy=" -l"
fi

debug=""
if test -n "$DEBUG"; then
	debug=" -d"
fi

# execute ext topology
exteid=`imunes$legacy$debug -b -e exrj ext.imn | awk '/Experiment/{print $4; exit}'`

startCheck "$exteid"

eid=`imunes$legacy$debug -b topo.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

echo "Checking if link l0 exists:"
if isOSlinux; then
	himage -E $eid ip link show l0 2>&1
else
	himage -E $eid ngctl show l0: 2>&1
fi

if [ $? -eq 0 ]; then
	netDump pc1@$exteid eth0 icmp
	if [ $? -eq 0 ]; then
		pingCheck pc1@$exteid 17.1.1.1 2
		if [ $? -eq 0 ]; then
			sleep 2
			readDump pc1@$exteid eth0
			if [ $? -ne 0 ]; then
				echo "ERROR: readDump failed"
				err=1
			fi
		else
			echo "ERROR: pingCheck failed"
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
	netDump pc2@$exteid eth0 icmp
	if [ $? -eq 0 ]; then
		pingCheck pc2@$exteid 17.2.1.1 2
		if [ $? -eq 0 ]; then
			sleep 2
			readDump pc2@$exteid eth0
			if [ $? -ne 0 ]; then
				echo "ERROR: readDump failed"
				err=1
			fi
		else
			echo "ERROR: pingCheck failed"
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

imunes$legacy$debug -b -e $eid

# terminate ext topology
imunes$legacy$debug -b -e $exteid

thereWereErrors $err
