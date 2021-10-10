#!/bin/bash

set -ex

export DEBIAN_FRONTEND=noninteractive

apt-get update -qy
apt-get upgrade -qy

# add users
UID_CATCHALL=1000
useradd -m --uid $UID_CATCHALL catchall

# install Postfix, Dovecot, and Mutt
debconf-set-selections <<< "postfix postfix/mailname string 'localhost'"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -qy postfix dovecot-imapd mutt


cat << EOF > /etc/postfix/main.cf
smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
biff = no

append_dot_mydomain = no

readme_directory = no

compatibility_level = 2

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level=may

smtp_tls_CApath=/etc/ssl/certs
smtp_tls_security_level=may
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = 'localhost', $myhostname, localhost.localdomain, localhost
relayhost =
mynetworks = 0.0.0.0/0 [::]/0
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

home_mailbox = .maildir/
smtputf8_enable = yes

# catchall configuration
virtual_gid_maps = static:${UID_CATCHALL}
virtual_mailbox_base = /var/mail/vhosts
virtual_mailbox_limit = 0
virtual_mailbox_domains = static:all
virtual_mailbox_maps = hash:/etc/postfix/vmailbox static:catchall/
virtual_minimum_uid = ${UID_CATCHALL}
virtual_uid_maps = static:${UID_CATCHALL}
EOF

cat << EOF > /etc/postfix/vmailbox
EOF

postmap /etc/postfix/vmailbox

mkdir -p /var/mail/vhosts/catchall
chown -R catchall:catchall /var/mail/vhosts
ln -s /var/mail/vhosts/catchall /home/catchall/.maildir

cat << EOF >> /etc/dovecot/users
catchall@any.tld:{PLAIN}secret:1000:1000::/home/catchall
EOF

sed -i 's|mbox:~/mail:INBOX=/var/mail/%u|maildir:/var/mail/vhosts/%d/%n|g' \
  /etc/dovecot/conf.d/10-mail.conf

cp /etc/skel/.muttrc /root

# services
systemctl enable postfix.service
systemctl enable dovecot.service

# cleanup
apt-get autoremove -qy
apt-get clean -qy

rm -rf /tmp/* /var/tmp/*

