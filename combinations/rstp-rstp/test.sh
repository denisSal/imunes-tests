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

limit=30
echo "Wait for RSTP to finish ($limit seconds)"
ctr=0
while test $ctr -lt $limit; do
	echo -n "."
	sleep 1
	ctr=$((ctr+1))
done
echo ""

echo "Checking if link l0 exists:"
if isOSlinux; then
	himage -E $eid ip link show l0 2>&1
else
	himage -E $eid ngctl show l0: 2>&1
fi

if [ $? -eq 0 ]; then
	netDump pc1@$eid eth0 icmp
	if [ $? -eq 0 ]; then
		pingCheck pc1@$eid 10.0.0.21 2
		if [ $? -eq 0 ]; then
			sleep 2
			readDump pc1@$eid eth0
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
	netDump pc1@$eid eth1 icmp
	if [ $? -eq 0 ]; then
		pingCheck pc1@$eid 10.0.1.21 2
		if [ $? -eq 0 ]; then
			sleep 2
			readDump pc1@$eid eth1
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

imunes$legacy -b -e $eid

thereWereErrors $err
