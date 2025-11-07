#!/bin/sh

. ../../common/procedures.sh

err=0
legacy=""
if test -n "$LEGACY"; then
	legacy=" -l"
fi

eid=`imunes$legacy -b vlanswitch.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

echo "Checking if link l0 exists:"
if isOSlinux; then
	himage -E $eid ip link show l0 2>&1
else
	himage -E $eid ngctl show l0: 2>&1
fi

if [ $? -eq 0 ]; then
	netDump pc1@$eid eth0 icmp
	if [ $? -eq 0 ]; then
		sleep 4
		pingCheck pc1@$eid 50.0.0.2 2
		if [ $? -eq 0 ]; then
			sleep 2
			readDump pc1@$eid eth0
			err=$?

			if [ $err -ne 1 ]; then
				pingCheck pc1@$eid 60.0.0.3 2
				if [ $? -eq 0 ]; then
					sleep 2
					readDump pc1@$eid eth0
					err=$?

					if [ $err -ne 1 ]; then
						pingCheck pc3@$eid 60.0.0.4 2
						if [ $? -eq 0 ]; then
							sleep 2
							readDump pc1@$eid eth0
							if [ $? -ne 0 ]; then
								echo "ERROR: readDump failed"
								err=1
							fi
						else
							echo "ERROR: VLAN6 -> VLAN6 pingCheck failed"
							err=1
						fi
					else
						echo "ERROR: netDump failed"
						err=1
					fi
				else
					echo "ERROR: TRUNK -> VLAN6 pingCheck failed"
					err=1
				fi
			else
				echo "ERROR: netDump failed"
				err=1
			fi
		else
			echo "ERROR: TRUNK -> VLAN5 pingCheck failed"
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

imunes$legacy -b -e $eid

thereWereErrors $err
