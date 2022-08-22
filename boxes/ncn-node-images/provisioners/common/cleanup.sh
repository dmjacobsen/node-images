#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
set -euo pipefail

echo "remove /etc/shadow entry for root"
seconds_per_day=$(( 60*60*24 ))
days_since_1970=$(( $(date +%s) / seconds_per_day ))
sed -i "/^root:/c\root:\*:$days_since_1970::::::" /etc/shadow

echo "remove root's .ssh directory"
rm -rvf /root/.ssh

echo "remove ssh host keys"
rm -fv /etc/ssh/ssh_host*

echo "removing our autoyast cache to ensure no lingering sensitive content remains there from install"
rm -rf /var/adm/autoinstall/cache

echo "cleanup all the downloaded RPMs"
zypper clean --all

echo "clean up network interface persistence"
rm -f /etc/udev/rules.d/70-persistent-net.rules;
touch /etc/udev/rules.d/75-persistent-net-generator.rules;

echo "truncate any logs that have built up during the install"
find /var/log/ -type f -name "*.log.*" -exec rm -rf {} \;
find /var/log -type f -exec truncate --size=0 {} \;

echo "remove the contents of /tmp and /var/tmp"
rm -rf /tmp/* /var/tmp/*

echo "blank netplan machine-id (DUID) so machines get unique ID generated on boot"
truncate -s 0 /etc/machine-id

echo "force a new random seed to be generated"
rm -f /var/lib/systemd/random-seed

echo "clear the history so our install isn't there"
rm -f /root/.wget-hsts
export HISTSIZE=0

# Handle ext2/3/4 or xfs.
echo "Running defrag -- this can take a while ... "
if ! e4defrag /; then
    if ! xfs_fsr /; then
        echo >&2 "Neither e4defrag nor xfs_fsr could defragment the root device. Potential filesystem mismatch on [/]."
        mount | grep ' / '
    fi
fi
echo 'Defrag completed'

echo "Write zeros..."
filler="$(($(df -BM --output=avail /|grep -v Avail|cut -d "M" -f1)-1024))"
dd if=/dev/zero of=/root/zero-file bs=1M count=$filler
rm -f /root/zero-file
