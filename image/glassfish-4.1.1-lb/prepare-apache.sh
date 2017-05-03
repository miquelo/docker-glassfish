#!/bin/sh

apt-get -y install apache2 libapache2-mod-jk

mkdir /usr/apache2
useradd \
-d /usr/apache2 \
-s /bin/bash \
apache2
echo "
PATH=\$HOME/bin:\$PATH
export PATH
" > /usr/apache2/.bash_profile
addgroup apache2 sudo
chown -R apache2:apache2 /usr/apache2
chown -R apache2 /etc/apache2

a2dissite 000-default
rm /etc/apache2/sites-available/000-default.conf
rm /etc/libapache2-mod-jk/workers.properties

mkdir /usr/apache2/lib
chown apache2:apache2 /usr/apache2/lib

touch /usr/apache2/lib/workers.properties
chown apache2:apache2 /usr/apache2/lib/workers.properties

mkdir /usr/apache2/bin
chown apache2:apache2 /usr/apache2/bin

echo '#!/bin/sh

echo "

ServerAdmin     webmaster@localhost
ServerName      localhost
" >> /etc/apache2/apache2.conf

echo "
<VirtualHost *:80>

    DocumentRoot                /var/www/html
	
    JkLogLevel                  debug
    JkLogStampFormat            \"[%a %b %d %H:%M:%S %Y] \"
    JkOptions                   +ForwardKeySize +ForwardURICompat \\\\
                                -ForwardDirectories
    JkRequestLogFormat          \"%w %V %T\"
    JkMount                     /* loadbalancer
    
    ErrorLog                    \${APACHE_LOG_DIR}/error.log
    CustomLog                   \${APACHE_LOG_DIR}/access.log combined
    
</VirtualHost>
" > /etc/apache2/sites-available/lb.conf

echo "
<VirtualHost _default_:443>

    DocumentRoot                /var/www/html
    
    SSLEngine on
    SSLCipherSuite              ALL:!ADH:!EXP56:RC4+RSA:\\\\
+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
    SSLCertificateFile          /usr/apache2/lib/cert.pem
    SSLCertificateKeyFile       /usr/apache2/lib/key.pem
    # SSLCertificateChainFile   /etc/apache2/ssl.crt/server-ca.crt
    # SSLCACertificatePath      /etc/ssl/certs/
    # SSLCACertificateFile      /etc/apache2/ssl.crt/ca-bundle.crt
    # SSLCARevocationPath       /etc/apache2/ssl.crl/
    # SSLCARevocationFile       /etc/apache2/ssl.crl/ca-bundle.crl
    
    # SSLVerifyClient           require
    # SSLVerifyDepth            10
    # SSLOptions                +FakeBasicAuth +ExportCertData +StrictRequire
    # BrowserMatch              "MSIE [2-6]" \\\\
    #                           nokeepalive ssl-unclean-shutdown \\\\
    #                           downgrade-1.0 force-response-1.0
    
    JkLogLevel                  debug
    JkLogStampFormat            \"[%a %b %d %H:%M:%S %Y] \"
    JkOptions                   +ForwardKeySize +ForwardURICompat \\\\
                                -ForwardDirectories
    JkRequestLogFormat          \"%w %V %T\"
    JkMount                     /* loadbalancer
    
    # SSL between load balancer and GlassFish Server
    # JkExtractSSL              On
    # JkHTTPSIndicator          HTTPS
    # JkSESSIONIndicator        SSL_SESSION_ID
    # JkCIPHERIndicator         SSL_CIPHER
    # JkCERTSIndicator          SSL_CLIENT_CERT
    
    LogLevel                    info ssl:warn
    
    ErrorLog                    \${APACHE_LOG_DIR}/error.log
    CustomLog                   \${APACHE_LOG_DIR}/access.log combined
    
</VirtualHost>
" > /etc/apache2/sites-available/lb-ssl.conf

SEARCH_PATTERN="JkWorkersFile \/etc\/libapache2-mod-jk\/workers.properties"
REPLACE_PATTERN="JkWorkersFile \/usr\/apache2\/lib\/workers.properties"
sed -ie "s/$SEARCH_PATTERN/$REPLACE_PATTERN/g" \
/etc/apache2/mods-enabled/jk.conf

sudo a2enmod ssl
sudo a2ensite lb
sudo a2ensite lb-ssl
' > /usr/apache2/bin/setup.sh
chmod +x /usr/apache2/bin/setup.sh

mv /tmp/setup/workers.py /usr/apache2/bin
chown apache2:apache2 /usr/apache2/bin/workers.py
chmod +x /usr/apache2/bin/workers.py

echo '#!/bin/sh
sudo apache2ctl `workers.py lib/workers.properties loadbalancer $@`
' > /usr/apache2/bin/lb.sh
chown apache2:apache2 /usr/apache2/bin/lb.sh
chmod +x /usr/apache2/bin/lb.sh

echo '
[program:apache2]
user=apache2
command=/usr/apache2/bin/setup.sh
' > /etc/supervisor/conf.d/apache2.conf

