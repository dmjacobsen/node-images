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

# Google artifacts built and deployed into GCP and used in vShasta.
source "googlecompute" "ncn-common" {
  instance_name           = "vshasta-${var.image_name}-builder-${var.artifact_version}"
  project_id              = "${var.google_destination_project_id}"
  network_project_id      = "${var.google_network_project_id}"
  source_image_project_id = "${var.google_source_image_project_id}"
  source_image_family     = "${var.google_source_image_family}"
  source_image            = "${var.google_source_image_name}"
  service_account_email   = "${var.google_service_account_email}"
  ssh_username            = "root"
  zone                    = "${var.google_zone}"
  image_family            = "${var.google_destination_image_family}"
  image_name              = "vshasta-${var.image_name}-${var.artifact_version}"
  image_description       = "build.source-artifact = ${var.google_source_image_url}, build.url = ${var.build_url}"
  machine_type            = "${var.google_machine_type}"
  subnetwork              = "${var.google_subnetwork}"
  disk_size               = "${var.google_disk_size_gb}"
  use_internal_ip         = "${var.google_use_internal_ip}"
  omit_external_ip        = "${var.google_use_internal_ip}"
}

# Metal artifacts are published to Artifactory and intended for running on real hardware.
# These are shipped to customers.
source "qemu" "ncn-common" {
  accelerator         = "${var.qemu_accelerator}"
  cpus                = "${var.cpus}"
  disk_cache          = "${var.disk_cache}"
  disk_discard        = "unmap"
  disk_detect_zeroes  = "unmap"
  disk_compression    = "${var.qemu_disk_compression}"
  skip_compaction     = "${var.qemu_skip_compaction}"
  disk_image          = true
  disk_size           = "${var.disk_size}"
  display             = "${var.qemu_display}"
  use_default_display = "${var.qemu_default_display}"
  memory              = "${var.memory}"
  headless            = "${var.headless}"
  iso_checksum        = "${var.source_iso_checksum}"
  iso_url             = "${var.source_iso_uri}"
  shutdown_command    = "echo '${var.ssh_password}'|/sbin/halt -h -p"
  ssh_password        = "${var.ssh_password}"
  ssh_username        = "${var.ssh_username}"
  ssh_wait_timeout    = "${var.ssh_wait_timeout}"
  output_directory    = "${var.output_directory}-qemu"
  vnc_bind_address    = "${var.vnc_bind_address}"
  vm_name             = "${var.image_name}.${var.qemu_format}"
  format              = "${var.qemu_format}"
}

# Not built by CI/CD; local-build-only.
# Intention: VirtualBox emulator for metal artifacts.
source "virtualbox-ovf" "ncn-common" {
  source_path      = "${var.vbox_source_path}"
  format           = "${var.vbox_format}"
  checksum         = "none"
  headless         = "${var.headless}"
  shutdown_command = "echo '${var.ssh_password}'|/sbin/halt -h -p"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "${var.ssh_wait_timeout}"
  output_directory = "${var.output_directory}-virtualbox-ovf"
  output_filename  = "${var.image_name}"
  vboxmanage       = [
    [
      "modifyvm",
      "{{ .Name }}",
      "--memory",
      "${var.memory}"
    ],
    [
      "modifyvm",
      "{{ .Name }}",
      "--cpus",
      "${var.cpus}"
    ]
  ]
  virtualbox_version_file = ".vbox_version"
  guest_additions_mode    = "disable"
}

build {
  sources = [
    "source.googlecompute.ncn-common",
    "source.qemu.ncn-common",
    "source.virtualbox-ovf.ncn-common"
  ]

  provisioner "shell" {
    inline = [
      "mkdir -pv /etc/ansible /srv/cray"
    ]
  }
  
  provisioner "file" {
    direction   = "upload"
    source      = "./vendor/github.com/Cray-HPE/metal-provision/ansible.cfg"
    destination = "/etc/ansible/ansible.cfg"
  }

  provisioner "file" {
    source      = "./vendor/github.com/Cray-HPE/csm-rpms"
    destination = "/srv/cray"
  }

  provisioner "shell" {
    environment_vars = [
      "ARTIFACTORY_USER=${var.artifactory_user}",
      "ARTIFACTORY_TOKEN=${var.artifactory_token}"
    ]
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; setup-package-repos'"
    ]
    valid_exit_codes = [0, 123]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; get-current-package-list /tmp/initial.packages explicit'",
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; get-current-package-list /tmp/initial.deps.packages deps'"
    ]
    only = ["qemu.ncn-common", "virtualbox-ovf.ncn-common"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-common/base.packages'"
    ]
    valid_exit_codes = [0, 123]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-common/google.packages'"
    ]
    valid_exit_codes = [0, 123]
    only             = ["googlecompute.ncn-common"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-common/metal.packages'"
    ]
    valid_exit_codes = [0, 123]
    only             = ["qemu.ncn-common", "virtualbox-ovf.ncn-common"]
  }

  provisioner "shell" {
    script = "${path.root}/provisioners/common/setup.sh"
  }

  provisioner "ansible-local" {
    inventory_file = "vendor/github.com/Cray-HPE/metal-provision/packer.yml"
    playbook_dir   = "vendor/github.com/Cray-HPE/metal-provision"
    playbook_file  = "vendor/github.com/Cray-HPE/metal-provision/pb_ncn_common.yml"
    command        = "source /etc/ansible/csm_ansible/bin/activate && ANSIBLE_STDOUT_CALLBACK=debug PYTHONUNBUFFERED=1 /etc/ansible/csm_ansible/bin/ansible-playbook --tags common"
  }

  provisioner "ansible-local" {
    inventory_file = "vendor/github.com/Cray-HPE/metal-provision/packer.yml"
    playbook_dir   = "vendor/github.com/Cray-HPE/metal-provision"
    playbook_file  = "vendor/github.com/Cray-HPE/metal-provision/pb_ncn_common.yml"
    command        = "source /etc/ansible/csm_ansible/bin/activate && ANSIBLE_STDOUT_CALLBACK=debug PYTHONUNBUFFERED=1 /etc/ansible/csm_ansible/bin/ansible-playbook --tags google"
    only           = ["googlecompute.ncn-common"]
  }

  provisioner "ansible-local" {
    inventory_file = "vendor/github.com/Cray-HPE/metal-provision/packer.yml"
    playbook_dir   = "vendor/github.com/Cray-HPE/metal-provision"
    playbook_file  = "vendor/github.com/Cray-HPE/metal-provision/pb_ncn_common.yml"
    command        = "source /etc/ansible/csm_ansible/bin/activate && ANSIBLE_STDOUT_CALLBACK=debug PYTHONUNBUFFERED=1 /etc/ansible/csm_ansible/bin/ansible-playbook --tags metal"
    only           = ["qemu.ncn-common", "virtualbox-ovf.ncn-common"]
  }

  provisioner "shell" {
    script = "${path.root}/provisioners/google/install.sh"
    only   = ["googlecompute.ncn-common"]
  }

  provisioner "shell" {
    script = "${path.root}/provisioners/metal/install.sh"
    only   = ["qemu.ncn-common", "virtualbox-ovf.ncn-common"]
  }

  provisioner "ansible-local" {
    inventory_file = "vendor/github.com/Cray-HPE/metal-provision/packer.yml"
    playbook_dir   = "vendor/github.com/Cray-HPE/metal-provision"
    playbook_file  = "vendor/github.com/Cray-HPE/metal-provision/pb_ncn_common_team.yml"
    command        = "source /etc/ansible/csm_ansible/bin/activate && ANSIBLE_STDOUT_CALLBACK=debug PYTHONUNBUFFERED=1 /etc/ansible/csm_ansible/bin/ansible-playbook --tags common"
  }

  provisioner "ansible-local" {
    inventory_file = "vendor/github.com/Cray-HPE/metal-provision/packer.yml"
    playbook_dir   = "vendor/github.com/Cray-HPE/metal-provision"
    playbook_file  = "vendor/github.com/Cray-HPE/metal-provision/pb_ncn_common_team.yml"
    command        = "source /etc/ansible/csm_ansible/bin/activate && ANSIBLE_STDOUT_CALLBACK=debug PYTHONUNBUFFERED=1 /etc/ansible/csm_ansible/bin/ansible-playbook --tags google"
    only           = ["googlecompute.ncn-common"]
  }

  provisioner "ansible-local" {
    inventory_file = "vendor/github.com/Cray-HPE/metal-provision/packer.yml"
    playbook_dir   = "vendor/github.com/Cray-HPE/metal-provision"
    playbook_file  = "vendor/github.com/Cray-HPE/metal-provision/pb_ncn_common_team.yml"
    command        = "source /etc/ansible/csm_ansible/bin/activate && ANSIBLE_STDOUT_CALLBACK=debug PYTHONUNBUFFERED=1 /etc/ansible/csm_ansible/bin/ansible-playbook --tags metal"
    only           = ["qemu.ncn-common", "virtualbox-ovf.ncn-common"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; get-current-package-list /tmp/installed.packages explicit'",
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; get-current-package-list /tmp/installed.deps.packages deps'",
      "bash -c 'zypper lr -e /tmp/installed.repos'"
    ]
    only = ["qemu.ncn-common", "virtualbox-ovf.ncn-common"]
  }

  provisioner "file" {
    direction = "download"
    sources   = [
      "/tmp/initial.deps.packages",
      "/tmp/initial.packages",
      "/tmp/installed.deps.packages",
      "/tmp/installed.packages",
      "/tmp/installed.repos"
    ]
    destination = "${var.output_directory}/"
    only        = ["qemu.ncn-common", "virtualbox-ovf.ncn-common"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; cleanup-package-repos'"
    ]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; cleanup-all-repos'"
    ]
  }

  provisioner "shell" {
    script = "${path.root}/provisioners/common/cleanup.sh"
  }

}
