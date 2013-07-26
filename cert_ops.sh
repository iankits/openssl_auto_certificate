#!/bin/bash
# Author: Ankit Singh, 2013
# 
# This is the script to automate the process to creating simple self-signed root CA and server certificate using the shell script
# 
# TEST Script with the following command:
# . cert_ops.sh create "DE" "HE" "FRA" "ME" "TEST" "CERT" "me@my.de"
#
# You are free to use this script but absolutely no warranty!
#
# TODO: 1. Fix usage i.e write to a function, 
#       2. write client certificate generation
#       3. make ca, server and client openration separate from command line

# Path to the folder where  Certificate to be Saved
PWD=.

## output filename
ca_key_file=ca.key
ca_cert_file=ca.crt
client_key_file=client.key
client_cert_file=client.cert
server_key_file=server.key
server_cert_file=server.crt

## Generate Server Config file
function gen_server_config(){
    echo -e "== Generating server.cnf =="
    cat > server.cnf << EOT
mode server

proto udp
dev tun
topology subnet

tls-server
ca ca.crt
cert server.crt
key server.key
dh dh1024.pem
remote-cert-tls client

port 1194

ifconfig 10.0.0.1 255.255.255.0
client-config-dir vpnclients.ccd

EOT
}

## TODO Generate Client Config file
function gen_client_config(){
    echo -e "== Generating client.cnf"
}

gen_config ()
{
    echo "Generating config.cnf"
    cat > config.cnf <<EOT
HOME                    = .
RANDFILE                = $ENV::HOME/.rnd
[ ca ]
default_ca      = CA_default
[ CA_default ]
certs           = .
crl_dir         = .
database        = index.txt
new_certs_dir   = .
certificate     = $2
serial          = serial
private_key     = $1
RANDFILE        = .rand
x509_extensions = usr_cert
name_opt        = ca_default
cert_opt        = ca_default
default_days    = 365
default_crl_days= 30
default_md      = sha1
preserve        = no
policy          = policy_match
[ policy_match ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional
[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional
[ req ]
default_bits            = 1024
default_md              = sha1
default_keyfile         = privkey.pem
distinguished_name      = req_distinguished_name
attributes              = req_attributes
x509_extensions = v3_ca
string_mask = MASK:0x2002
[ req_distinguished_name ]
countryName                     = DE
countryName_default             = $C
countryName_min                 = 2
countryName_max                 = 2
stateOrProvinceName             = HE
stateOrProvinceName_default     = $ST
localityName                    = Frankfurt
localityName_default            = $L
0.organizationName              = Organization Name (eg, company)
0.organizationName_default      = $O
organizationalUnitName          = $OU
commonName                      = $CN
commonName_max                  = 64
emailAddress                    = $EMAILAD
emailAddress_max                = 64
[ req_attributes ]
challengePassword               = A challenge password
challengePassword_min           = 4
challengePassword_max           = 20
unstructuredName                = An optional company name
[ usr_cert ]
basicConstraints=CA:FALSE
nsComment                       = "OpenSSL Generated Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = CA:true
[xpclient_ext]
extendedKeyUsage = 1.3.6.1.5.5.7.3.2
[xpserver_ext]
extendedKeyUsage = 1.3.6.1.5.5.7.3.1
EOT
}

## This function sets the values as per command line attributes passed
function fill_user_provided_value {
C=$2
ST=$3
L=$4
O=$5
OU=$6
CN=$7
EMAILAD=$8
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

function print_attributes {
    echo -e "C=$C\nST=$ST\nL=$L\nO=$O\nOU=$OU\nCN=$CN\nEMAILADDRESS=$EMAILAD\n"
}

##  This function checks and validates the command line attributes
function check_command_line_input {
if [ $# -eq 1 ]; then
	# fill the default value for certificate
	constructor_to_setup_values
	echo -e "== NO ARGUMENTS == \n### WARNING! Creating Certificate with DEFAULT Value" 
	print_attributes
else
	if [ $# -eq 8 ]; then
		echo " == Filling the values for certificate using Users Supplied value"
		echo -e "\n== Creating Certificate with User Provided attributes value ==" 
		fill_user_provided_value $@
		print_attributes

	else
		echo -e "### WRONG PARAMETER SUPPLIED ###"
		echo -e "\n### SYNTAX:  ./cert_ops.sh create "DE" "HE" "Fra" "ME" "TEST" "CERT" "me@my.de"\n "
		echo -e " ### WARNING! Creating Certificate with DEFAULT Value ## "
		constructor_to_setup_values
		print_attributes
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

function create_server_cert_sign {
    echo -e "\n== Generating and Sign Server Certificate =="
    
    if [ ! -f index.txt ]
    then
	touch $PWD/index.txt
    fi
    
    if [ ! -f serial ]
    then
        echo 01 > $PWD/serial
    fi
    
    if [ $server_cert_file != `cat serial.old`.pem ]
    then
        rm `cat $PWD/serial.old`.pem
    fi
    
    gen_config $PWD/$ca_key_file $PWD/$ca_cert_file
    
    echo "\n###### generating server cert:$server_key_file, $server_cert_file";
    echo -e "$C\n$ST\n$L\n$O\n$OU\n$CN\n$EMAILAD\n\n\n" | openssl req -config config.cnf -new -nodes -keyout $PWD/$server_key_file -out temp.csr -days 3650
    
    echo -e "y\ny\n\n" | openssl ca -config config.cnf -policy policy_anything -out $PWD/$server_cert_file -days 3650 -key whatever -extensions xpserver_ext -infiles temp.csr
   
    rm $PWD/temp.csr $PWD/config.cnf 
    
}

case $1 in
    clean)
	if [ -f `cat $PWD/serial.old`.pem ]
	then
            rm `cat $PWD/serial.old`.pem
	fi
	
	rm $PWD/index.txt* $PWD/ca.* $PWD/ser*
	;;
    create)
	check_command_line_input $@
	create_root_ca
	gen_server_config
	create_server_cert_sign
	;;
    *) 
	echo -e "USAGE: \n cert_ops clean \n cert_ops create"
	;;
esac