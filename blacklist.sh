#!/bin/bash

PATH_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IP_LIST="$PATH_ROOT/ipList"
LOG_PATH="$PATH_ROOT/log"
PATH_REPORT="$PATH_ROOT/reports"

DATE="$(date +"%A %d %B %Y - %H:%M ")"
DATE_DAY="$(date +"%Y-%m-%d")"

BLISTS="
bl.0spam.org
nbl.0spam.org
url.0spam.org
b.barracudacentral.org
bb.barracudacentral.org
bl.deadbeef.com
bl.mailspike.net
bl.score.senderscore.com
bl.spamcop.net
bl.spameatingmonkey.net
blackholes.five-ten-sg.com
blacklist.woody.ch
bogons.cymru.com
cbl.abuseat.org
cdl.anti-spam.org.cn
combined.abuse.ch
combined.rbl.msrbl.net
db.wpbl.info
dnsbl-1.uceprotect.net
dnsbl-2.uceprotect.net
dnsbl-3.uceprotect.net
dnsbl.inps.de
dnsbl.sorbs.net
drone.abuse.ch
duinv.aupads.org
dul.dnsbl.sorbs.net
dul.ru
dyna.spamrats.com
dynip.rothen.com
http.dnsbl.sorbs.net
images.rbl.msrbl.net
ips.backscatterer.org
ix.dnsbl.manitu.net
korea.services.net
misc.dnsbl.sorbs.net
noptr.spamrats.com
ohps.dnsbl.net.au
omrs.dnsbl.net.au
orvedb.aupads.org
osps.dnsbl.net.au
osrs.dnsbl.net.au
owfs.dnsbl.net.au
owps.dnsbl.net.au
pbl.spamhaus.org
phishing.rbl.msrbl.net
probes.dnsbl.net.au
proxy.bl.gweep.ca
proxy.block.transip.nl
psbl.surriel.com
rbl.interserver.net
rdts.dnsbl.net.au
relays.bl.gweep.ca
relays.bl.kundenserver.de
relays.nether.net
residential.block.transip.nl
ricn.dnsbl.net.au
rmst.dnsbl.net.au
sbl.spamhaus.org
smtp.dnsbl.sorbs.net
socks.dnsbl.sorbs.net
spam.dnsbl.sorbs.net
spam.rbl.msrbl.net
spam.spamrats.com
spamlist.or.kr
spamrbl.imp.ch
t3direct.dnsbl.net.au
tor.dnsbl.sectoor.de
torserver.tor.dnsbl.sectoor.de
ubl.lashback.com
ubl.unsubscore.com
virbl.bit.nl
virus.rbl.msrbl.net
web.dnsbl.sorbs.net
wormrbl.imp.ch
xbl.spamhaus.org
zen.spamhaus.org
zombie.dnsbl.sorbs.net
"



makeReport(){
	echo "From: Notificaciones SOC <socnotify.fw@gmail.com>" > "$PATH_REPORT/Report-$DATE_DAY"
	echo "To: Soporte SOC <soporte@fwingenieria.com>" >> "$PATH_REPORT/Report-$DATE_DAY"
	echo "Subject: REPORTE DE ESTADO DE BLACKLIST $DATE_DAY" >> "$PATH_REPORT/Report-$DATE_DAY"
	echo "Date: $DATE" >> "$PATH_REPORT/Report-$DATE_DAY"
	echo " " >> "$PATH_REPORT/Report-$DATE_DAY"
	echo " " >> "$PATH_REPORT/Report-$DATE_DAY"
	echo "Reporte re estado de listado de Ip's publicas de las diferentes entidades" >> "$PATH_REPORT/Report-$DATE_DAY"
	echo " " >> "$PATH_REPORT/Report-$DATE_DAY"
}


ERROR() {
		echo $0 ERROR: $Iip >&2
		exit 2
	}

makeReport

for Iip in $(cat $IP_LIST)
	do

	

# -- Sanity check on parameters
#[ $# -ne 1 ] && ERROR 'Please specify a single IP address'

# -- if the address consists of 4 groups of minimal 1, maximal digits, separated by '.'
# -- reverse the order
# -- if the address does not match these criteria the variable 'reverse will be empty'

	reverse=$(echo $Iip |
			sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")

	if [ "x${reverse}" = "x" ] ; then

		ERROR  "IMHO '$Iip' doesn't look like a valid IP address"
		exit 1

	fi

		# Assuming an IP address of 11.22.33.44 as parameter or argument

		# If the IP address in $0 passes our crude regular expression check,
		# the variable  ${reverse} will contain 44.33.22.11
		# In this case the test will be:
		#   [ "x44.33.22.11" = "x" ]
		# This test will fail and the program will continue

		# An empty '${reverse}' means that shell argument $1 doesn't pass our simple IP address check
		# In that case the test will be:
		#   [ "x" = "x" ]
		# This evaluates to true, so the script will call the ERROR function and quit

		# -- do a reverse ( address -> name) DNS lookup



	REVERSE_DNS=$(dig +short -x $Iip)

	echo IP $1 NAME ${REVERSE_DNS:----} "$LOG_PATH/$Iip-$DATE_DAY"

	# -- cycle through all the blacklists
	for BL in ${BLISTS} ; do
		# show the reversed IP and append the name of the blacklist
		printf "%-60s" " ${reverse}.${BL}."

		# use dig to lookup the name in the blacklist
		#echo "$(dig +short -t a ${reverse}.${BL}. |  tr '\n' ' ')"
		LISTED="$(dig +short -t a ${reverse}.${BL}.)"

		if [[ ! -z "$LISTED" ]]; then

			echo "This IP: -- $Iip -- is in blacklist listed: -- $BL --" >> "$PATH_REPORT/Report-$DATE_DAY"
		fi

		echo ${LISTED:----}


		printf "%-60s" " ${reverse}.${BL}." >> "$LOG_PATH/$Iip-$DATE_DAY"
		echo ${LISTED:----} >> "$LOG_PATH/$Iip-$DATE_DAY"
	done
done

curl --ssl smtp://smtp.gmail.com --mail-from email.mail@gmail.com --mail-rcpt email.mail@gmail.com --upload-file "$PATH_REPORT/Report-$DATE_DAY" --user 'email.mail@gmail.com:P4$$w0rd'
