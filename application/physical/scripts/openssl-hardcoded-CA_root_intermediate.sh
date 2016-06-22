#!/usr/bin/env bash
#
# A script implementing (parts of) https://jamielinux.com/docs/openssl-certificate-authority/index.html
# ToDo: startdate
#

_PATH='/cygdrive/c/Users/christian.prior/Desktop/openssltests/script1'
cd $_PATH

for dir in helotism-root-CA helotism-root-CA/certs helotism-root-CA/crl helotism-root-CA/private helotism-root-CA/newcerts; do
  if [ ! -d ${_PATH}/${dir} ]; then mkdir -p ${_PATH}/${dir}; fi
done

chmod 700 ${_PATH}/helotism-root-CA/private

if [ ! -f ${_PATH}/helotism-root-CA/index ]; then touch ${_PATH}/helotism-root-CA/index; fi
if [ ! -f ${_PATH}/helotism-root-CA/serial ]; then echo 1000 > ${_PATH}/helotism-root-CA/serial; fi

if [ -f ./openssl-root.cnf ]; then cp ./openssl-root.cnf ${_PATH}/helotism-root-CA/openssl.cnf ; fi

if [ ! -f ${_PATH}/helotism-root-CA/private/ca.key.pem ]; then
echo "Create the root key (ca.key.pem)"
openssl genrsa -aes256 -out ${_PATH}/helotism-root-CA/private/ca.key.pem 4096
chmod 400 ${_PATH}/helotism-root-CA/private/ca.key.pem
else
  echo "The root key ./private/ca.key.pem already exists."
fi

if [ ! -f ${_PATH}/helotism-root-CA/certs/ca.cert.pem ]; then
  echo "Use the root key (ca.key.pem) to create a root certificate (ca.cert.pem)"
  day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futureyear=$(( $year + 20 ));
  days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${month}${day}" +%s) )/(60*60*24) ))
  openssl req -config ${_PATH}/helotism-root-CA/openssl.cnf -key ${_PATH}/helotism-root-CA/private/ca.key.pem -new -x509 -days ${days} \
  -sha256 -extensions v3_ca -out ${_PATH}/helotism-root-CA/certs/ca.cert.pem
  chmod 444 ${_PATH}/helotism-root-CA/certs/ca.cert.pem
  openssl x509 -text -in ${_PATH}/helotism-root-CA/certs/ca.cert.pem -noout | grep -A 1 X509v3
else
  echo "The root certificate ./certs/ca.cert.pem already exists."
  openssl x509 -text -in ${_PATH}/helotism-root-CA/certs/ca.cert.pem -noout | grep -A 1 X509v3
fi



### The intermediate CA

for dir in  helotism-intermediate-CA helotism-intermediate-CA/certs helotism-intermediate-CA/csr helotism-intermediate-CA/crl helotism-intermediate-CA/private helotism-intermediate-CA/newcerts; do
  if [ ! -d ${_PATH}/${dir} ]; then mkdir -p ${_PATH}/${dir}; fi
done

chmod 700 ${_PATH}/helotism-intermediate-CA/private

if [ ! -f ${_PATH}/helotism-intermediate-CA/index ]; then touch ${_PATH}/helotism-intermediate-CA/index; fi
if [ ! -f ${_PATH}/helotism-intermediate-CA/serial ]; then echo 1000 > ${_PATH}/helotism-intermediate-CA/serial; fi
if [ ! -f ${_PATH}/helotism-intermediate-CA/crlnumber ]; then echo 1000 > ${_PATH}/helotism-intermediate-CA/crlnumber; fi

if [ -f ./openssl.cnf ]; then cp ./openssl.cnf ${_PATH}/helotism-intermediate-CA/ ; fi


if [ ! -f ${_PATH}/helotism-intermediate-CA/index ]; then touch ${_PATH}/helotism-intermediate-CA/index; fi
if [ ! -f ${_PATH}/helotism-intermediate-CA/serial ]; then echo 1000 > ${_PATH}/helotism-intermediate-CA/serial; fi

if [ -f ./openssl-intermediate.cnf ]; then cp ./openssl-intermediate.cnf ${_PATH}/helotism-intermediate-CA/openssl.cnf ; fi

if [ ! -f ${_PATH}/helotism-intermediate-CA/private/intermediate.key.pem ]; then
echo "Create the intermediate key (intermediate.key.pem)"
openssl genrsa -aes256 -out ${_PATH}/helotism-intermediate-CA/private/intermediate.key.pem 4096
chmod 400 ${_PATH}/helotism-intermediate-CA/private/intermediate.key.pem
else
  echo "The intermediate key ./private/intermediate.key.pem already exists."
fi


if [ ! -f ${_PATH}/helotism-intermediate-CA/csr/intermediate.csr.pem ]; then
  echo "Use the intermediate key to create a certificate signing request (CSR)."
  openssl req -config ${_PATH}/helotism-intermediate-CA/openssl.cnf -new -sha256 -key \
    ${_PATH}/helotism-intermediate-CA/private/intermediate.key.pem \
    -out ${_PATH}/helotism-intermediate-CA/csr/intermediate.csr.pem
fi

if [ ! -f /helotism-intermediate-CA/certs/intermediate.cert.pem ]; then
  echo "To create an intermediate certificate, use the root CA with the v3_intermediate_ca extension to sign the intermediate CSR."
  #Signing as root
  day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futureyear=$(( $year + 10 ));
  days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${month}${day}" +%s) )/(60*60*24) ))
  openssl ca -config ${_PATH}/helotism-root-CA/openssl.cnf -extensions v3_intermediate_ca \
    -days ${days} -notext -md sha256 \
    -in ${_PATH}/helotism-intermediate-CA/csr/intermediate.csr.pem \
    -out ${_PATH}/helotism-intermediate-CA/certs/intermediate.cert.pem
  chmod 444 ${_PATH}/helotism-intermediate-CA/private/intermediate.key.pem
  openssl x509 -text -in ${_PATH}/helotism-intermediate-CA/certs/intermediate.cert.pem -noout | grep -A 1 X509v3
fi
echo "Verify the intermediate certificate"
openssl verify -CAfile ${_PATH}/helotism-root-CA/certs/ca.cert.pem ${_PATH}/helotism-intermediate-CA/certs/intermediate.cert.pem

echo "Create the certificate chain file"
cat ${_PATH}/helotism-intermediate-CA/certs/intermediate.cert.pem ${_PATH}/helotism-root-CA/certs/ca.cert.pem > ${_PATH}/helotism-intermediate-CA/certs/ca-chain.cert.pem
chmod 444 ${_PATH}/helotism-intermediate-CA/certs/ca-chain.cert.pem



### Sign server and client certificates

for host in axle.wheel.prdv.de spoke01.wheel.prdv.de spoke02.wheel.prdv.de cog01.wheel.prdv.de cog02.wheel.prdv.de; do

  if [ ! -f ${_PATH}/helotism-intermediate-CA/private/${host}.key.pem ]; then
    echo "Create a key without passphrase."
    openssl genrsa -out ${_PATH}/helotism-intermediate-CA/private/${host}.key.pem 2048
    chmod 400 ${_PATH}/helotism-intermediate-CA/private/${host}.key.pem
  fi

  if [ ! -f ${_PATH}/helotism-intermediate-CA/private/${host}.csr.pem ]; then
    echo "Use the private key to create a certificate signing request (CSR)"
    openssl req -config ${_PATH}/helotism-intermediate-CA/openssl.cnf \
      -subj "/CN=${host}" \
      -key ${_PATH}/helotism-intermediate-CA/private/${host}.key.pem \
      -new -sha256 -out ${_PATH}/helotism-intermediate-CA/private/${host}.csr.pem
  fi

  if [ ! -f ${_PATH}/helotism-intermediate-CA/private/${host}.cert.pem ]; then
    day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futuremonth=$(( $month + 1 )); futureyear=$(( $year + 1 ));
    days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${futuremonth}${day}" +%s) )/(60*60*24) ))
    openssl ca -config ${_PATH}/helotism-intermediate-CA/openssl.cnf \
      -extensions server_cert -days ${days} -notext -md sha256 \
      -in ${_PATH}/helotism-intermediate-CA/private/${host}.csr.pem \
      -out ${_PATH}/helotism-intermediate-CA/private/${host}.cert.pem
  chmod 444 ${_PATH}/helotism-intermediate-CA/private/${host}.cert.pem
  fi

  echo "Verify the certificate for ${host}"
  openssl x509 -noout -text \
        -in ${_PATH}/helotism-intermediate-CA/private/${host}.cert.pem

  echo "Use the CA certificate chain file to verify that the new certificate has a valid chain of trust."
  openssl verify -CAfile ${_PATH}/helotism-intermediate-CA/certs/ca-chain.cert.pem ${_PATH}/helotism-intermediate-CA/private/${host}.cert.pem



done #for host