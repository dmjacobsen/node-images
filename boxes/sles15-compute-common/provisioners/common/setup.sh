#!/bin/bash

set -e

echo "Initializing log location(s)"
mkdir -p /var/log/cray
cat << 'EOF' > /etc/logrotate.d/cray
/var/log/cray/*.log {
  size 1M
  create 744 root root
  rotate 4
}
EOF

echo "Initializing directories and resources"
mkdir -p /srv/cray
cp -r /tmp/files/* /srv/cray/
chmod +x -R /srv/cray/scripts
rm -rf /tmp/files
cp /srv/cray/sysctl/common/* /etc/sysctl.d/
cp /srv/cray/limits/98-cray-limits.conf /etc/security/limits.d/98-cray-limits.conf

# TODO: default root ssh key details should be parameterized. These keys should ALWAYS
# be overridden at install/upgrade time based on customer configuration, and thus these
# built-in ones should really only be relevant for any needed build-time needs. Nonetheless,
# this should still not be hard-coded, it was just originally translated from previous build
# scripts to reduce impact during transitional periods
echo "Setting up default, initial root SSH configuration/credentials"
mkdir -p /root/.ssh
cat > /root/.ssh/id_rsa << EOF
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
EOF
cat > /root/.ssh/id_rsa.pub << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCur7HKgx1zfarSuEHQMSs2XzErwDJc3WN8rSnz0+w39QJz04KtpFnzF+0P25OCtCwZAGwicglzFSUgCkZ+K355BkGHJwJJ9bcgG3aDcl0bAUwatPiWV8LulMtBLgiAeX1abIoZGiJiUN3IAdbNIhwph7JjoMUgzTM1XQVbsvCluu3PFTx2Ha82NQGyiNCN1j1gWBbK2U4fPrSziTfJYy5elEfa4uu/iRremvbZD41Mb6UxYDBSTGjZSFv+x14AWugXEaMi5nFAFeOQtJak+YCChgxrvaYliJMmkeFdwYScVo1tnPiKmAu3F2cwRo/KZCR4ZxSkiyjwEki34Amn25WR
EOF
cat > /root/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCur7HKgx1zfarSuEHQMSs2XzErwDJc3WN8rSnz0+w39QJz04KtpFnzF+0P25OCtCwZAGwicglzFSUgCkZ+K355BkGHJwJJ9bcgG3aDcl0bAUwatPiWV8LulMtBLgiAeX1abIoZGiJiUN3IAdbNIhwph7JjoMUgzTM1XQVbsvCluu3PFTx2Ha82NQGyiNCN1j1gWBbK2U4fPrSziTfJYy5elEfa4uu/iRremvbZD41Mb6UxYDBSTGjZSFv+x14AWugXEaMi5nFAFeOQtJak+YCChgxrvaYliJMmkeFdwYScVo1tnPiKmAu3F2cwRo/KZCR4ZxSkiyjwEki34Amn25WR
EOF
chmod 600 /root/.ssh/id_rsa
chmod 644 /root/.ssh/id_rsa.pub
chmod 644 /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chown -R root:root /root

# Change hostname from lower layer to ncn.
echo 'ncn' > /etc/hostname

# Lock the kernel before we move onto installing anything for NCNs
uname -r
rpm -qa kernel-default
zypper addlock kernel-default

# Install jq
command -v jq >/dev/null 2>&1 || zypper -n install --auto-agree-with-licenses jq=1.6-3.3.1
