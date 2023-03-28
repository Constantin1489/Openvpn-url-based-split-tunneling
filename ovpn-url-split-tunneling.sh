#!/bin/bash

set -x
function removeTEMPfile()
{
    rm $TEMPOVPN
}

# put your working directory which contains a ovpnfile, a filter and a user pass.
WORKINGDIR=$PWD

# put your ovpnfile
OVPNFILE=$1
OVPN_SPLIT_FILTER=${WORKINGDIR}/ovpn_filter_example.txt

# put your AUTH_USER_PASS file in WORKINGDIR.
AUTH_USER_PASS=${WORKINGDIR}/protonvpn_auth.conf
TEMPOVPN=$(mktemp $WORKINGDIR/TEMPOVPN.XXXXXXXX)


# add your urls.
# mimic the url style
# if you have your filter file, comment the code block (the 22 ~ 26 line) and chagne OVPN_SPLIT_FILTER.
cat<< EOF >$OVPN_SPLIT_FILTER
route-nopull
route checkip.dyndns.org 255.255.255.255
route dyndns.org 255.255.255.255
EOF

if [[ $(pgrep openvpn) ]]
then
    pgrep openvpn | xargs -I {} sudo kill -TERM -- -{}
    echo 'killed the process'
else

    # merge the url redirection rules with the ovpn file to the temp file.
    gsed -e "/^proto/r $OVPN_SPLIT_FILTER" $OVPNFILE >> ${TEMPOVPN}

    sudo openvpn --auth-nocache --config ${TEMPOVPN} \
				--auth-user-pass $AUTH_USER_PASS  \
				--daemon && echo "openvpn runs"

    echo "wait.."
    sleep 5
    # check a changed ip address
    curl -s http://checkip.dyndns.org/
fi

# remove $TEMPOVPN when this script exits.
trap removeTEMPfile EXIT
set +x
