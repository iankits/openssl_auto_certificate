#!/bin/bash
# Author: Ankit Singh, 2013
# 
# This is the script to automate the process to creating simple 
# self-signed root CA, server and client certificate using the shell script
#
# This script also generates Diffie-Hellman parameters for the server side.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# TEST Script with the following command:
# . cert_ops.sh createALL "DE" "HE" "FRA" "ME" "TEST" "CERT" "me@my.de"
#
# Read README for details syntax options and some tweaks
#
# 

#DEBUG
#set -x 
# Path to the folder where  Certificate to be Saved
PWD=.

# Server Address for OpenVPN Client
SERVER_IP=192.168.1.55

## output filename
ca_key_file=ca_key.pem
ca_cert_file=ca_crt.pem
client_key_file=client_key.pem
client_cert_file=client_crt.pem
client_cnf=client_cnf.pem
server_key_file=server_key.pem
server_cert_file=server_crt.pem
server_cnf=server.cnf
client_cnf=client.cnf

CONFIG=config.cnf

## Parameters for generating diffie helman key
KEY_DIR=$PWD
KEY_SIZE=1024

## Generate Server Config file for OpenVPN
gen_server_config (){
    echo -e "== Generating server.cnf =="
    cat > $server_cnf << EOT
mode server

proto udp
dev tun
topology subnet

tls-server
ca $ca_cert_file
cert $server_cert_file
key $server_key_file
dh dh1024.pem

port 1194

server 10.0.0.1/24 255.255.255.0
client-config-dir vpnclients.ccd

EOT
}

## Generate Client Config for OpenVPN
gen_client_config(){
    echo -e "== Generating $client_cnf =="
 cat > $client_cnf << EOT
proto udp
dev tun
topology subnet
tls-client
ca $ca_cert_file
cert $client_cert_file
key $client_key_file
remote $SERVER_IP 
rport 1194
pull 

EOT
}

gen_config ()
{
    echo "Generating $CONFIG"
    cat > $CONFIG <<EOT
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
fill_user_provided_value () {
C=$1
ST=$2
L=$3
O=$4
OU=$5
CN=$6
EMAILAD=$7
}

## Provides default values to create CA. Can be anything.
constructor_to_setup_values() {
C="DE"
ST="HE"
L="Frankfurt"
O="MY COMPANY ONLINE"
OU="SAMPLE"
CN="Sample Certificate"
EMAILAD="me@my.com"
}

print_attributes () {
    echo -e "C=$C\nST=$ST\nL=$L\nO=$O\nOU=$OU\nCN=$CN\nEMAILADDRESS=$EMAILAD\n"
}

##  This function checks and validates the command line attributes
check_command_line_input () {
if [ $# -eq 1 ]; then
	# fill the default value for certificate
	constructor_to_setup_values
	echo -e "== NO ARGUMENTS == \n### WARNING! Creating Certificate with DEFAULT Value" 
	print_attributes
else
	if [ $# -eq 8 ]; then
		echo " == Filling the values for certificate using Users Supplied value"
		echo -e "\n== Creating Certificate with User Provided attributes value ==" 
		fill_user_provided_value $2 $3 $4 $5 $6 $7 $8
		print_attributes
else
	## Check if it is client request
	if [[ "$1" == "client" ]]; then
	 	echo -e " ### Creating Certificate for the client ### "
		if [[ "$2" == '' ]]; then
        		echo -e "\n ## WARNING: Creating Certificate with Default Name: $client_cert_file"
			constructor_to_setup_values
			print_attributes
		else
        		client_cert_file=$2_crt.pem
			client_cnf=$2.cnf
			client_key_file=$2_key.pem
        		echo -e "\n == Creating Certificate with Client Name: $client_cert_file =="
 			## Check if user provided the value for certifcate generation
			if [ $# -eq 9 ]; then
                		echo " == Filling the values for certificate using Users Supplied value"
                		echo -e "\n== Creating Certificate with User Provided attributes value =="
                		fill_user_provided_value $3 $4 $5 $6 $7 $8 $9
                		print_attributes
			else
				constructor_to_setup_values
				CN=$2
        			echo -e "== NO ARGUMENTS == \n### WARNING! Creating Certificate with DEFAULT Value"
        			print_attributes
			fi
		fi

	
	else
		echo -e "### WRONG PARAMETER SUPPLIED ###"
		echo -e "\n### SYNTAX:  ./cert_ops.sh create "DE" "HE" "Fra" "ME" "TEST" "CERT" "me@my.de"\n "
		echo -e " ### WARNING! Creating Certificate with DEFAULT Value ## "
		constructor_to_setup_values
		print_attributes
	fi
	fi
fi
} 

## This function creates and self-sign root CA
create_root_ca () {
    echo -e "\n##### root CA Certificate Started #####\n"
    echo -e "$C\n$ST\n$L\n$O\n$OU\n$CN\n$EMAILAD\n\n\n" | openssl req -new -x509 -outform PEM -newkey rsa:2048 -nodes -keyout $PWD/$ca_key_file -keyform PEM -out $PWD/$ca_cert_file -days 365
  #echo -e "$C\n$ST\n$L\n$O\n$OU\n$CN\n$EMAILAD\n\n\n" | openssl req -config $CONFIG -new -x509 -extensions v3_ca -days 3650 -passin pass:whatever -passout pass:whatever -keyout $PWD/$ca_key_file -out $PWD/$ca_cert_file 
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
	echo $PASS | openssl pkcs12 -export -in $PWD/$ca_cert_file -inkey $PWD/$ca_key_file -out $PWD/ca.p12 -name "CA" -passout stdin
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

#Creates server certificate and signed by CA
create_server_cert_sign () {
    echo -e "\n== Generating and Sign Server Certificate =="
    
    if [ ! -f $PWD/index.txt ]
    then
	touch $PWD/index.txt
    fi
    
    if [ ! -f $PWD/serial ]
    then
        echo 01 > $PWD/serial
    fi
    
    if [ ! -f $PWD/$CONFIG ]
    then
	echo -e "## Cannot find $CONFIG file.... Generating new one....!"
    	gen_config $PWD/$ca_key_file $PWD/$ca_cert_file
    fi

    echo "\n###### generating server cert:$server_key_file, $server_cert_file";
    echo -e "$C\n$ST\n$L\n$O\n$OU\n$CN\n$EMAILAD\n\n\n" | openssl req -config $CONFIG -new -nodes -keyout $PWD/$server_key_file -out temp.csr -days 3650
    
    echo -e "y\ny\n\n" | openssl ca -config $CONFIG -policy policy_anything -out $PWD/$server_cert_file -days 3650 -key whatever -extensions xpserver_ext -infiles temp.csr
   
    if [ ! -f $PWD/$server_key_file ]
    then
		chmod 600 $PWD/$server_key_file
    fi

    rm $PWD/temp.csr

    if [ $PWD/$server_cert_file != `cat $PWD/serial.old`.pem ]
    then
        rm `cat $PWD/serial.old`.pem
    fi
    
}

# create client certificate and signed by CA.
create_client_cert_sign () {
echo " == Generating and Signing Client Certificate"

 if [ ! -f $PWD/index.txt ]
    then
        touch $PWD/index.txt
    fi

    if [ ! -f $PWD/serial ]
    then
        echo 01 > $PWD/serial
    fi

    if [ ! -f $PWD/$CONFIG ]
    then
	echo -e "## Cannot find $CONFIG file.... Generating new one....!"
	gen_config $PWD/$ca_key_file $PWD/$ca_cert_file
    fi
	
    echo -e "\n###### generating client cert:$client_key_file, $client_cert_file";
    echo -e "$C\n$ST\n$L\n$O\n$OU\n$CN\n$EMAILAD\n\n\n" | openssl req -config $CONFIG -new -nodes -keyout $PWD/$client_key_file -out temp.csr -days 3650

    echo -e "y\ny\n\n" | openssl ca -config $CONFIG -policy policy_anything -out $PWD/$client_cert_file  -days 3650 -key whatever -extensions xpclient_ext -infiles temp.csr
	
    if [ ! -f $PWD/$client_key_file ]
    then
        chmod 600 $PWD/$client_key_file
    fi

    rm $PWD/temp.csr

    if [ $PWD/$client_cert_file != `cat $PWD/serial.old`.pem ]
    then
        rm `cat $PWD/serial.old`.pem
    fi
}

#
# Build Diffie-Hellman parameters for the server side
# of an SSL/TLS connection.
#
generate_dh_key () {
if test $KEY_DIR; then
    openssl dhparam -out ${KEY_DIR}/dh${KEY_SIZE}.pem ${KEY_SIZE}
else
    echo you must define KEY_DIR
fi

}

case $1 in
    clean)
	rm $PWD/ca* $PWD/index.txt* $PWD/ser* $PWD/client* $PWD/*.cnf
	;;
    createALL)
	check_command_line_input $@
	create_root_ca
	gen_server_config
	create_server_cert_sign
	create_client_cert_sign $@
	;;
    ca)
	check_command_line_input $@
        create_root_ca	
	;;
    server)
	check_command_line_input $@
	
	if [ ! -f $PWD/$server_cnf ]; then
      		gen_server_config
        fi
        create_server_cert_sign
	;;
    client)
	check_command_line_input $@
	
        if [ ! -f $PWD/$client_cnf ]; then
             gen_client_config
        fi
	create_client_cert_sign $@
	
	;;
    dh)
	generate_dh_key
	;;
    *) 
	echo -e "USAGE (See README for detail description): \n $0 clean #removes all cerficates and keys \n $0 createALL #Creates CA, Server & client Certificate \n $0 ca #Creates CA \n $0 server \n $0 client <clientCertificateName> #Creates client certificate \n $0 dh # builds Diffie-Hellman parameters for the server side"
	;;
esac

