#!/bin/bash
#
# Cray System Management : METAL
# To be installed on all mediums (Google, Metal, etc.)
set -e

function cloud_metal {
    echo 'Setting cloud-init metal config'
    local base=/etc/cloud

    # Clean out any pre-existing configs; nothing should exist in the ncn-common layer here.
    mkdir -pv $base || echo "$base already exists"
    rsync -av --delete /srv/cray/resources/metal/cloud/cloud.cfg.d/ ${base}/cloud.cfg.d/ || echo 'No cloud-init configs to copy.'
    rsync -av /srv/cray/resources/metal/cloud/templates/ ${base}/templates/ || echo 'No templates to copy.'
}
cloud_metal

function motd {
    # Add motd/flair
    cp -pv /srv/cray/resources/common/motd /etc/motd
}
motd
