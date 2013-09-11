openssl_auto_certificate
========================

This is the script to automate the process to creating simple self-signed root CA, server
and client certificate using the shell script.

This script also outputs OpenVPN specific configuration file for the server and clients.

USAGE (the script will pick default value from it when you not provide all seven attributes):

* Generating CA and Self Signing it:

        ./cert_ops.sh ca "DE" "HE" "FRA" "ME" "CA" "CERT" "me@CA.de"
 OR
        ./cert_ops.sh ca

* Generating Server certificate and Signing it:

        ./cert_ops.sh server "DE" "HE" "FRA" "ME" "server" "CERT" "me@server.de"
 OR
        ./cert_ops server

* Generating Client certificate and Signing it with CA:

        ./cert_ops.sh client client1 "DE" "HE" "FRA" "ME" "client1" "CERT" "client1@myorg.de"
 OR
        ./cert_ops.sh client

* Generating all certificates with default values (WARNING: this will create the certificate with same attributes)

        ./cert_ops.sh createALL "DE" "HE" "FRA" "ME" "CA" "CERT" "me@CA.de"
 OR
        ./cert_ops.sh createALL

* CLEANING / Deleting all generated certificates, keys and configuration files by the script

        ./cert_ops.sh clean

PS: if all certificate are generated with same values then the script might not work. It will throw error like this

        :failed to update database
        TXT_DB error number 2

You need to make a tweak in "index.txt.attr" file.

You need to change "unique_subject = yes" to "unique_subject = no"

Then try again and it will work. This is done basically for security reason which is not recommended. But for testing
purpose you can use this trick to get going.
