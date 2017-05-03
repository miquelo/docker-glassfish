#!/bin/sh

apt-get -y install wget unzip

echo "Downloading GlassFish Server..."
mkdir -p /tmp/setup/tmp
wget -P /tmp/setup/tmp \
http://download.java.net/glassfish/4.1.1/release/\
glassfish-4.1.1.zip 2>> /dev/null

unzip /tmp/setup/tmp/glassfish-4.1.1*zip -d /usr/lib
rm -f /tmp/setup/tmp/glassfish-4.1.1*zip

useradd \
-d /usr/lib/glassfish4 \
-s /bin/bash \
glassfish
echo "
PATH=\$HOME/bin:\$PATH
export PATH
" > /usr/lib/glassfish4/.bash_profile
chown -R glassfish:glassfish /usr/lib/glassfish4

su - glassfish << EOF
# Deleting default domain
asadmin \
delete-domain \
domain1

mkdir .ssh
EOF

rm -rf /usr/lib/glassfish4/glassfish/domains/

sed -ie 's/="..\/domains"/="\/var\/glassfish\/domains"/g' \
/usr/lib/glassfish4/glassfish/config/asenv.conf
sed -ie 's/="..\/nodes"/="\/var\/glassfish\/nodes"/g' \
/usr/lib/glassfish4/glassfish/config/asenv.conf

mkdir -p /var/glassfish/domains
mkdir -p /var/glassfish/nodes
chown -R glassfish:glassfish /var/glassfish

apt-get -y remove wget unzip

echo '#!/bin/sh

# Enable password authentication
if [ ! -z ${GLASSFISH_SSH_PASSWORD+x} ]
then
	echo "glassfish:$GLASSFISH_SSH_PASSWORD" | chpasswd
fi

# Create glassfish public key
su - glassfish << EOF
ssh-keygen -b 2048 -t rsa -f .ssh/id_rsa -q -N ""
EOF' > /usr/lib/glassfish4/bin/setup.sh

chmod +x /usr/lib/glassfish4/bin/setup.sh

echo '#!/bin/sh

ssh -oStrictHostKeyChecking=no $1@$2 "mkdir -p $3/$4/agent" 2> /dev/null
scp -oStrictHostKeyChecking=no \
$5/$6/config/master-password $1@$2:$3/$4/agent 2> /dev/null
' > /usr/lib/glassfish4/bin/install-master-password.sh

chown glassfish:glassfish /usr/lib/glassfish4/bin/install-master-password.sh
chmod u+x /usr/lib/glassfish4/bin/install-master-password.sh

echo '#!/bin/sh

keytool \
-importkeystore \
-srckeystore $1/$2/config/keystore.jks \
-srcalias s2as \
-srcstorepass $3 \
-destkeystore /tmp/$2-keystore.p12 \
-deststoretype PKCS12 \
-deststorepass $3 2> /dev/null

openssl pkcs12 \
-in /tmp/$2-keystore.p12 \
-passin pass:$3 \
-nokeys \
-out /tmp/$2-cert.pem

openssl pkcs12 \
-in /tmp/$2-keystore.p12 \
-passin pass:$3 \
-nocerts \
-nodes \
-out /tmp/$2-key.pem

rm /tmp/$2-keystore.p12

scp -oStrictHostKeyChecking=no \
/tmp/$2-cert.pem $4@$5:/usr/apache2/lib/cert.pem 2> /dev/null
rm /tmp/$2-cert.pem

scp -oStrictHostKeyChecking=no \
/tmp/$2-key.pem $4@$5:/usr/apache2/lib/key.pem 2> /dev/null
rm /tmp/$2-key.pem
' > /usr/lib/glassfish4/bin/install-certificates.sh

chown glassfish:glassfish /usr/lib/glassfish4/bin/install-certificates.sh
chmod u+x /usr/lib/glassfish4/bin/install-certificates.sh

echo '#!/bin/sh

KEYSTORE_TEMP_PATH=/tmp/keystore-$1

mkdir -p $KEYSTORE_TEMP_PATH
' > /usr/lib/glassfish4/bin/keystore-setup-begin.sh

chown glassfish:glassfish /usr/lib/glassfish4/bin/keystore-setup-begin.sh
chmod u+x /usr/lib/glassfish4/bin/keystore-setup-begin.sh

echo '#!/bin/sh

KEYSTORE_TEMP_PATH=/tmp/keystore-$1
KEYSTORE_PATH=/var/glassfish/domains/$1/config/keystore.jks
CACERTS_PATH=/var/glassfish/domains/$1/config/cacerts.jks

openssl pkcs12 \
-export \
-name s2as \
-out $KEYSTORE_TEMP_PATH/certkey \
-inkey $KEYSTORE_TEMP_PATH/private-key \
-in $KEYSTORE_TEMP_PATH/subject \
-passout pass:$2

keytool \
-importkeystore \
-srckeystore $KEYSTORE_TEMP_PATH/certkey \
-srcstoretype PKCS12 \
-srcalias s2as \
-srcstorepass $2 \
-destkeystore $KEYSTORE_PATH \
-deststoretype JKS \
-destalias s2as \
-deststorepass $2 2> /dev/null

keytool \
-import \
-alias s2as \
-file $KEYSTORE_TEMP_PATH/issuer \
-keystore $CACERTS_PATH \
-noprompt \
-storepass $2 2> /dev/null

rm -r $KEYSTORE_TEMP_PATH
' > /usr/lib/glassfish4/bin/keystore-setup-end.sh

chown glassfish:glassfish /usr/lib/glassfish4/bin/keystore-setup-end.sh
chmod u+x /usr/lib/glassfish4/bin/keystore-setup-end.sh

echo '
[program:glassfish]
command=/usr/lib/glassfish4/bin/setup.sh
' > /etc/supervisor/conf.d/glassfish.conf

