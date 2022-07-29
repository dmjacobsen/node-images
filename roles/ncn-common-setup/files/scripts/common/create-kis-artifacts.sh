#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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
set -e
trap cleanup EXIT

function cleanup {
    if ! umount -v /mnt/squashfs ; then
        echo 'no mount to cleanup'
    fi
    rm -rf /mnt/squashfs
}

# Source common dracut parameters.
. "$(dirname $0)/dracut-lib.sh"

# This facilitates creating the artifacts in the NCN pipeline.
mkdir -pv /mnt/squashfs /squashfs
mount -v -o bind / /mnt/squashfs

if [[ "$1" != "squashfs-only" ]]; then
    echo "Creating initrd/kernel artifacts"
    
    # NOTE: These mounts help create metal artifacts when running inside of the NCN pipeline, they are not necessary when this script runs
    #       on a physical server. These are harmless enough that they're always mounted, regardless of context.
    if [ "$(stat -c %d:%i / >/dev/null 2>&1)" != "$(stat -c %d:%i /proc/1/root/. 2>&1 >/dev/null)" ]; then
      echo "Not mounting proc, run, dev, sys, or var since we are in a chroot."
    else
        mkdir -pv /mnt/squashfs/dev /mnt/squashfs/proc /mnt/squashfs/run /mnt/squashfs/sys /mnt/squashfs/var
        mount --bind /dev /mnt/squashfs/dev
        mount --bind /proc /mnt/squashfs/proc
        mount --bind /tmp /mnt/squashfs/run
        mount --bind /sys /mnt/squashfs/sys
        mount --bind /var /mnt/squashfs/var
    fi
    
    # This has been here since we first made images, more or less as a last/final check that we have no cache left-over from the auto-install.  
    [ -f /var/adm/autoinstall/cache ] && rm -rf /var/adm/autoinstall/cache
    
    unshare -R /mnt/squashfs bash -c "dracut \
        --add \"$(printf '%s' "${ADD[*]}")\" \
        --force \
        --kver ${KVER} \
        --no-hostonly \
        --no-hostonly-cmdline \
        --printsize \
        /tmp/initrd.img.xz"

    # Recreate the kdump initrd; this will ensure i    
    unshare -R /mnt/squashfs bash -c "mkdumprd -K /boot/vmlinuz-${KVER} -I /boot/initrd-${KVER}-kdump -f"
    
    cp -v /mnt/squashfs/boot/vmlinuz-${KVER} /squashfs/${KVER}.kernel
    cp -v /mnt/squashfs/tmp/initrd.img.xz /squashfs/initrd.img.xz
    rm -f /mnt/squashfs/tmp/initrd.img.xz
    chmod 644 /squashfs/initrd.img.xz

    if [ "$(stat -c %d:%i / >/dev/null 2>&1)" != "$(stat -c %d:%i /proc/1/root/. 2>&1 >/dev/null)" ]; then
        echo "Not unmouting dev, proc, run, sys, or var because we're in a chroot."
    else
          umount -v /mnt/squashfs/dev /mnt/squashfs/proc /mnt/squashfs/run /mnt/squashfs/sys /mnt/squashfs/var
    fi
fi

if [[ "$1" != "kernel-initrd-only" ]]; then
  echo "Creating squashfs artifact"
  mksquashfs /mnt/squashfs /squashfs/filesystem.squashfs -no-xattrs -comp gzip -no-exports -noappend -no-recovery -processors "$(nproc)" -e /mnt/squashfs/squashfs/filesystem.squashfs
fi
