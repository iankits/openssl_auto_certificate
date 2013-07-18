#!/bin/sh
# Author: Ankit Singh, 2013
# 
# This is the script to automate the process to creating simple self-signed root CA and server certificate using the shell script
# 
# TEST Script with the following command:
# . cert_ops.sh "DE" "HE" "FRA" "ME" "TEST" "CERT" "me@my.de"
#
# You are free to use this script but absolutely no warranty!
# 
# TODO: write function for creating and signing Server certificate

PWD=.

## This function sets the values as per command line attributes passed
function fill_user_provided_value {

C=$0
ST=$1
L=$2
O=$3
OU=$4
CN=$5
EMAILAD=$6

}

## Provides default values to create CA. Can be anything.
function constructor_to_setup_values {

C="DE"
ST="HE"
L="Frankfurt"
O="MY COMPANY ONLINE"
OU="SAMPLE"
CN="Sample Certificate"
EMAILAD="me@my.com"

}

##  This function checks and validates the command line attributes
function check_command_line_input {

if [ $# -eq 0 ]; then
	echo -e "== NO ARGUMENTS == \n== WARNING! Creating Certificate with DEFAULT Value =="
	echo -e "C=$C\nST=$ST\nL=$L\nO=$O\n$OU=OU\n$CN=CN\nEMAILADDRESS=$EMAILAD\n" 
	constructor_to_setup_values # fill the default value for certificate

else
	if [ $# -eq 7 ]; then
		echo " == Filling the values for certificate using Users Supplied value"
		fill_user_provided_value
	else
		echo -e "### WRONG PARAMETER SUPPLIED ###"
		echo -e "\n\n### SYNTAX:  ./cert_ops.sh "AT" "HE" "Fra" "ME" "TEST" "CERT" "me@my.de"\n "
		echo -e " ### WARNING! Creating Certificate with DEFAULT Value ## "
		constructor_to_setup_values
	fi

fi
} 

## This function creates and self-sign root CA
function create_root_ca {

echo -e "\n##### root CA Certificate Started #####\n"
echo -e "$C\n$ST\n$L\n$O\n$OU\n$CN\n$EMAILAD\n\n\n" | openssl req -new -x509 -outform PEM -newkey rsa:2048 -nodes -keyout $PWD/ca.key -keyform PEM -out $PWD/ca.crt -days 365

if [ $? -eq 0 ]; then
	echo -e "\n ##### root CA certificate SUCCESS \n"
	
	echo -e "\n### Please enter Password or Press Enter to give default password (Password123)"
	read PASS
	## Checks input whether it is empty or not
	if [ -n "$PASS" ]; then
		 echo -e "\n### Thank God! You are not Lazy! :-P ###"
	else
		PASS="Password123"
	fi
	
	echo -e "### The password to be entered: $PASS"
	echo $PASS | openssl pkcs12 -export -in $PWD/ca.crt -inkey $PWD/ca.key -out ca.p12 -name "CA" -passout stdin
else
	echo -e "\n ##### root CA creation failed!"
	exit 1
fi

if [ $? -eq 0 ]; then
	echo -e "\n ##### root CA self sign certificate SUCCESS ca.p12 \n"
else
	echo -e "\n ##### root CA self signing Failed!"
	exit 1
fi
}

#function create_server_cert_sign {
#echo "generating server cert:$1, $2";
#    openssl req -config ca_config.cnf -new -nodes -keyout $1 -out temp.csr -days 3650

#    openssl ca -config ca_config.cnf -policy policy_anything -out $2 -days 3650 -key whatever -extensions xpserver_ext -infiles temp.csr

#    rm temp.csr
#}

check_command_line_input $@
create_root_ca
