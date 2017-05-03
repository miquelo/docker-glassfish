#!/bin/sh

apt-get -y install openssh-server

SEARCH_PATTERN="#StrictModes yes"
REPLACE_PATTERN="StrictModes yes"
sed -ie "s/$SEARCH_PATTERN/$REPLACE_PATTERN/g" \
/etc/ssh/sshd_config

SEARCH_PATTERN="#PubkeyAuthentication yes"
REPLACE_PATTERN="PubkeyAuthentication yes"
sed -ie "s/$SEARCH_PATTERN/$REPLACE_PATTERN/g" \
/etc/ssh/sshd_config


SEARCH_PATTERN="#AuthorizedKeysCommand none"
REPLACE_PATTERN="AuthorizedKeysCommand \/usr\/bin\/authkeys"
sed -ie "s/$SEARCH_PATTERN/$REPLACE_PATTERN/g" \
/etc/ssh/sshd_config

SEARCH_PATTERN="#AuthorizedKeysCommandUser nobody"
REPLACE_PATTERN="AuthorizedKeysCommandUser authkeys"
sed -ie "s/$SEARCH_PATTERN/$REPLACE_PATTERN/g" \
/etc/ssh/sshd_config

useradd -r -s /bin/false authkeys

echo '#!/bin/sh
DIR="~${1}/.ssh/authorized_keys.dir/*"
cat `eval echo $DIR`
' > /usr/bin/authkeys
chmod 0555 /usr/bin/authkeys

mkdir -p /var/run/sshd
chmod 0755 /var/run/sshd

echo '
[program:sshd]
command=/usr/sbin/sshd
' > /etc/supervisor/conf.d/sshd.conf

