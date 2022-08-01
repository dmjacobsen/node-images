#
# MIT License
#
# (C) Copyright 2014-2022 Hewlett Packard Enterprise Development LP
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
source "googlecompute" "kubernetes" {
  instance_name           = "vshasta-${var.image_name_k8s}-builder-${var.artifact_version}"
  project_id              = "${var.google_destination_project_id}"
  network_project_id      = "${var.google_network_project_id}"
  source_image_project_id = "${var.google_source_image_project_id}"
  source_image_family     = "${var.google_source_image_family}"
  source_image            = "${var.google_source_image_name}"
  service_account_email   = "${var.google_service_account_email}"
  ssh_username            = "root"
  zone                    = "${var.google_zone}"
  image_family            = "vshasta-kubernetes-rc"
  image_name              = "vshasta-${var.image_name_k8s}-${var.artifact_version}"
  image_description       = "build.source-artifact = ${var.google_source_image_url}, build.url = ${var.build_url}"
  machine_type            = "${var.google_machine_type}"
  subnetwork              = "${var.google_subnetwork}"
  disk_size               = "${var.google_disk_size_gb}"
  use_internal_ip         = "${var.google_use_internal_ip}"
  omit_external_ip        = "${var.google_use_internal_ip}"
}

source "qemu" "kubernetes" {
  accelerator         = "${var.qemu_accelerator}"
  use_default_display = "${var.qemu_default_display}"
  display             = "${var.qemu_display}"
  cpus                = "${var.cpus}"
  disk_cache          = "${var.disk_cache}"
  disk_size           = "${var.disk_size}"
  memory              = "${var.memory}"
  iso_checksum        = "${var.source_iso_checksum}"
  iso_url             = "${var.source_iso_uri}"
  headless            = "${var.headless}"
  shutdown_command    = "echo '${var.ssh_password}'|/sbin/halt -h -p"
  ssh_password        = "${var.ssh_password}"
  ssh_username        = "${var.ssh_username}"
  ssh_wait_timeout    = "${var.ssh_wait_timeout}"
  output_directory    = "${var.output_directory}/kubernetes"
  vm_name             = "${var.image_name_k8s}.${var.qemu_format}"
  disk_image          = true
  disk_discard        = "unmap"
  disk_detect_zeroes  = "unmap"
  disk_compression    = true
  skip_compaction     = false
  vnc_bind_address    = "${var.vnc_bind_address}"
}

source "virtualbox-ovf" "kubernetes" {
  source_path      = "${var.vbox_source_path}"
  format           = "${var.vbox_format}"
  checksum         = "none"
  headless         = "${var.headless}"
  shutdown_command = "echo '${var.ssh_password}'|/sbin/halt -h -p"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "${var.ssh_wait_timeout}"
  output_directory = "${var.output_directory}/kubernetes"
  output_filename  = "${var.image_name_k8s}"
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

source "qemu" "storage-ceph" {
  accelerator         = "${var.qemu_accelerator}"
  use_default_display = "${var.qemu_default_display}"
  display             = "${var.qemu_display}"
  cpus                = "${var.cpus}"
  disk_cache          = "${var.disk_cache}"
  disk_size           = "${var.disk_size}"
  memory              = "${var.memory}"
  iso_url             = "${var.source_iso_uri}"
  iso_checksum        = "none"
  headless            = "${var.headless}"
  shutdown_command    = "echo '${var.ssh_password}'|/sbin/halt -h -p"
  ssh_password        = "${var.ssh_password}"
  ssh_username        = "${var.ssh_username}"
  ssh_wait_timeout    = "${var.ssh_wait_timeout}"
  output_directory    = "${var.output_directory}/storage-ceph"
  vm_name             = "${var.image_name_ceph}.${var.qemu_format}"
  disk_image          = true
  disk_discard        = "unmap"
  disk_detect_zeroes  = "unmap"
  disk_compression    = true
  skip_compaction     = false
  vnc_bind_address    = "${var.vnc_bind_address}"
}

source "virtualbox-ovf" "storage-ceph" {
  source_path      = "${var.vbox_source_path}"
  format           = "${var.vbox_format}"
  checksum         = "none"
  headless         = "${var.headless}"
  shutdown_command = "echo '${var.ssh_password}'|/sbin/halt -h -p"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "${var.ssh_wait_timeout}"
  output_directory = "${var.output_directory}/storage-ceph"
  output_filename  = "${var.image_name_ceph}"
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

source "googlecompute" "storage-ceph" {
  instance_name           = "vshasta-${var.image_name_ceph}-builder-${var.artifact_version}"
  project_id              = "${var.google_destination_project_id}"
  network_project_id      = "${var.google_network_project_id}"
  source_image_project_id = "${var.google_source_image_project_id}"
  source_image_family     = "${var.google_source_image_family}"
  source_image            = "${var.google_source_image_name}"
  service_account_email   = "${var.google_service_account_email}"
  ssh_username            = "root"
  zone                    = "${var.google_zone}"
  image_family            = "vshasta-storage-ceph-rc"
  image_name              = "vshasta-${var.image_name_ceph}-${var.artifact_version}"
  image_description       = "build.source-artifact = ${var.google_source_image_url}, build.url = ${var.build_url}"
  machine_type            = "${var.google_machine_type}"
  subnetwork              = "${var.google_subnetwork}"
  disk_size               = "${var.google_disk_size_gb}"
  use_internal_ip         = "${var.google_use_internal_ip}"
  omit_external_ip        = "${var.google_use_internal_ip}"
}

build {
  sources = [
    "source.googlecompute.kubernetes",
    "source.googlecompute.storage-ceph",
    "source.qemu.kubernetes",
    "source.qemu.storage-ceph",
    "source.virtualbox-ovf.kubernetes",
    "source.virtualbox-ovf.storage-ceph"
  ]

  provisioner "shell" {
    inline = [
      "mkdir -pv /srv/cray"
    ]
  }

  provisioner "file" {
    sources = [
      "${path.root}/${source.name}/files/",
      "./vendor/github.com/Cray-HPE/csm-rpms"
    ]
    destination = "/srv/cray"
  }

  provisioner "shell" {
    inline = [
      "bash -c 'if [ -f /root/zero.file ]; then rm /root/zero.file; fi'"
    ]
  }

  provisioner "shell" {
    script = "${path.root}/provisioners/common/setup.sh"
  }

  # setup.sh only exists for storage-ceph at this time.
  provisioner "shell" {
    script = "${path.root}/${source.name}/provisioners/common/setup.sh"
    only   = ["virtualbox-ovf.storage-ceph", "qemu.storage-ceph"]
  }

  # Placeholder: if/when Google needs a setup.sh (e.g. actions before RPMs are installed).
  #  provisioner "shell" {
  #    script = "${path.root}/provisioners/google/setup.sh"
  #    only = ["googlecompute.kubernetes", "googlecompute.storage-ceph"]
  #  }

  # Placeholder: if/when Metal needs a setup.sh (e.g. actions before RPMs are installed).
  #  provisioner "shell" {
  #    script = "${path.root}/provisioners/metal/setup.sh"
  #    only = ["virtualbox-ovf.kubernetes", "qemu.kubernetes", "virtualbox-ovf.storage-ceph", "qemu.storage-ceph"]
  #  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; get-current-package-list /tmp/initial.packages explicit'",
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; get-current-package-list /tmp/initial.deps.packages deps'"
    ]
    except = ["googlecompute.kubernetes", "googlecompute.storage-ceph"]
  }

  // Install packages by context (e.g. base (a.k.a. common), google, or metal)
  provisioner "shell" {
    environment_vars = [
      "CUSTOM_REPOS_FILE=${var.custom_repos_file}",
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
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-kubernetes/base.packages'"
    ]
    only = ["virtualbox-ovf.kubernetes", "qemu.kubernetes", "googlecompute.kubernetes"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-kubernetes/google.packages'"
    ]
    only = ["googlecompute.kubernetes"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-kubernetes/metal.packages'"
    ]
    only = ["virtualbox-ovf.kubernetes", "qemu.kubernetes"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-storage-ceph/base.packages'"
    ]
    only = ["virtualbox-ovf.storage-ceph", "qemu.storage-ceph", "googlecompute.storage-ceph"]
  }

  # Placeholder: if/when Google needs packages installed.
  #  provisioner "shell" {
  #    inline = ["bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-storage-ceph/google.packages'"]
  #    only = ["googlecompute.storage-ceph"]
  #  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; install-packages /srv/cray/csm-rpms/packages/node-image-storage-ceph/metal.packages'"
    ]
    only = ["virtualbox-ovf.storage-ceph", "qemu.storage-ceph"]
  }

  # Placeholder: if/when common needs an install.sh (e.g. actions before RPMs are installed).
  #  provisioner "shell" {
  #    script = "${path.root}/provisioners/common/install.sh"
  #  }

  # Placeholder: if/when Google needs an install.sh (e.g. actions before RPMs are installed).
  #  provisioner "shell" {
  #    script = "${path.root}/provisioners/google/install.sh"
  #    only = ["googlecompute.kubernetes", "googlecompute.storage-ceph"]
  #  }

  # Placeholder: if/when Metal needs an install.sh (e.g. actions before RPMs are installed).
  #  provisioner "shell" {
  #    script = "${path.root}/provisioners/metal/install.sh"
  #    only = ["virtualbox-ovf.kubernetes", "qemu.kubernetes", "virtualbox-ovf.storage-ceph", "qemu.storage-ceph"]
  #  }

  provisioner "shell" {
    environment_vars = [
      "DOCKER_IMAGE_REGISTRY=${var.docker_image_registry}",
      "K8S_IMAGE_REGISTRY=${var.k8s_image_registry}",
      "QUAY_IMAGE_REGISTRY=${var.quay_image_registry}"
    ]
    script = "${path.root}/${source.name}/provisioners/common/install.sh"
  }

  provisioner "shell" {
    script = "${path.root}/${source.name}/provisioners/google/install.sh"
    only   = ["googlecompute.kubernetes", "googlecompute.storage-ceph"]
  }

  provisioner "shell" {
    script = "${path.root}/${source.name}/provisioners/metal/install.sh"
    only   = ["qemu.storage-ceph", "qemu.kubernetes", "virtualbox-ovf.kubernetes", "virtualbox-ovf.storage-ceph"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; get-current-package-list /tmp/installed.packages explicit'",
      "bash -c '. /srv/cray/csm-rpms/scripts/rpm-functions.sh; get-current-package-list /tmp/installed.deps.packages deps'",
      "bash -c 'zypper lr -e /tmp/installed.repos'"
    ]
    only = [
      "qemu.kubernetes",
      "virtualbox-ovf.kubernetes",
      "qemu.storage-ceph",
      "virtualbox-ovf.storage-ceph"
    ]
  }

  provisioner "file" {
    direction = "download"
    sources   = [
      "/tmp/initial.deps.packages",
      "/tmp/initial.packages",
      "/tmp/installed.deps.packages",
      "/tmp/installed.packages"
    ]
    destination = "${var.output_directory}/${source.name}/"
    only        = [
      "qemu.kubernetes", "virtualbox-ovf.kubernetes", "qemu.storage-ceph",
      "virtualbox-ovf.storage-ceph"
    ]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/installed.repos"
    destination = "${var.output_directory}/${source.name}/installed.repos"
    only        = [
      "qemu.kubernetes", "virtualbox-ovf.kubernetes", "qemu.storage-ceph",
      "virtualbox-ovf.storage-ceph"
    ]
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

  provisioner "shell" {
    script = "${path.root}/provisioners/google/cleanup.sh"
    only   = [
      "googlecompute.kubernetes",
      "googlecompute.storage-ceph"
    ]
  }

  provisioner "shell" {
    script = "${path.root}/provisioners/metal/cleanup.sh"
    only   = [
      "qemu.kubernetes", "virtualbox-ovf.kubernetes", "qemu.storage-ceph",
      "virtualbox-ovf.storage-ceph"
    ]
  }

  provisioner "shell" {
    inline = [
      "bash -c 'goss -g /srv/cray/tests/common/ncn-common-tests.yml validate -f junit | tee /tmp/goss_common_out.xml'",
      "bash -c 'goss -g /srv/cray/tests/common/${source.name}-tests.yml validate -f junit | tee /tmp/goss_${source.name}_out.xml'"
    ]
  }

  provisioner "shell" {
    inline = [
      "bash -c 'goss -g /srv/cray/tests/google/ncn-common-tests.yml validate -f junit | tee /tmp/goss_google_out.xml'",
      "bash -c 'goss -g /srv/cray/tests/google/${source.name}-tests.yml validate -f junit | tee /tmp/goss_${source.name}_google_out.xml'"
    ]
    only = ["googlecompute.kubernetes"]
    #    only = ["googlecompute.kubernetes", "googlecompute.storage-ceph"]
  }

  provisioner "shell" {
    inline = [
      "bash -c 'goss -g /srv/cray/tests/metal/ncn-common-tests.yml validate -f junit | tee /tmp/goss_metal_out.xml'",
      "bash -c 'goss -g /srv/cray/tests/metal/${source.name}-tests.yml validate -f junit | tee /tmp/goss_${source.name}_metal_out.xml'"
    ]
    only = [
      "qemu.kubernetes", "virtualbox-ovf.kubernetes", "qemu.storage-ceph",
      "virtualbox-ovf.storage-ceph"
    ]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/goss_common_out.xml"
    destination = "${var.output_directory}/test-results-common.xml"
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/goss_${source.name}_out.xml"
    destination = "${var.output_directory}/test-results-${source.name}.xml"
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/goss_google_out.xml"
    destination = "${var.output_directory}/test-results-ncn-google.xml"
    only        = ["googlecompute.kubernetes"]
    #    only        = ["googlecompute.kubernetes", "googlecompute.storage-ceph"]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/goss_${source.name}_google_out.xml"
    destination = "${var.output_directory}/test-results-${source.name}-google.xml"
    only        = ["googlecompute.kubernetes"]
    #    only        = ["googlecompute.kubernetes", "googlecompute.storage-ceph"]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/goss_metal_out.xml"
    destination = "${var.output_directory}/test-results-ncn-metal.xml"
    only        = [
      "qemu.kubernetes", "virtualbox-ovf.kubernetes", "qemu.storage-ceph",
      "virtualbox-ovf.storage-ceph"
    ]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/goss_${source.name}_metal_out.xml"
    destination = "${var.output_directory}/test-results-${source.name}-metal.xml"
    only        = [
      "qemu.kubernetes", "virtualbox-ovf.kubernetes", "qemu.storage-ceph",
      "virtualbox-ovf.storage-ceph"
    ]
  }

  provisioner "shell" {
    inline = [
      "bash -c '/srv/cray/scripts/common/create-kis-artifacts.sh'"
    ]
    only = ["qemu.kubernetes", "qemu.storage-ceph"]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/squashfs/"
    destination = "${var.output_directory}/${source.name}/"
    only        = ["qemu.kubernetes", "qemu.storage-ceph"]
  }

  provisioner "shell" {
    inline = [
      "bash -c '/srv/cray/scripts/common/cleanup-kis-artifacts.sh'"
    ]
    only = ["qemu.kubernetes", "qemu.storage-ceph"]
  }

  post-processors {
    post-processor "shell-local" {
      inline = [
        "if grep '<failure>' ${var.output_directory}/test-results-common.xml ; then echo >&2 'Error: goss test failures found! See build output for details'; exit 1; fi",
        "if grep '<failure>' ${var.output_directory}/test-results-${source.name}.xml ; then echo >&2 'Error: goss test failures found! See build output for details'; exit 1; fi"
      ]
    }
    post-processor "shell-local" {
      inline = [
        "if grep '<failure>' ${var.output_directory}/test-results-ncn-google.xml ; then echo >&2 'Error: goss test failures found! See build output for details'; exit 1; fi",
        "if grep '<failure>' ${var.output_directory}/test-results-${source.name}-google.xml ; then echo >&2 'Error: goss test failures found! See build output for details'; exit 1; fi"
      ]
      only = ["googlecompute.kubernetes"]
      #      only = ["googlecompute.kubernetes", "googlecompute.storage-ceph"]
    }
    post-processor "shell-local" {
      inline = [
        "if grep '<failure>' ${var.output_directory}/test-results-ncn-metal.xml ; then echo >&2 'Error: goss test failures found! See build output for details'; exit 1; fi",
        "if grep '<failure>' ${var.output_directory}/test-results-${source.name}-metal.xml ; then echo >&2 'Error: goss test failures found! See build output for details'; exit 1; fi"
      ]
      only = [
        "qemu.kubernetes", "virtualbox-ovf.kubernetes", "qemu.storage-ceph",
        "virtualbox-ovf.storage-ceph"
      ]
    }
    post-processor "shell-local" {
      inline = [
        "echo 'Rename filesystem.squashfs and move remaining files to receive the image ID'",
        "ls -lR ./${var.output_directory}/${source.name}",
        "mv ${var.output_directory}/${source.name}/squashfs/filesystem.squashfs ${var.output_directory}/${source.name}/${source.name}.squashfs",
        "mv ${var.output_directory}/${source.name}/squashfs/*.kernel ${var.output_directory}/${source.name}/",
        "mv ${var.output_directory}/${source.name}/squashfs/initrd.img.xz ${var.output_directory}/${source.name}/",
        "rm -rf ${var.output_directory}/${source.name}/squashfs",
      ]
      only = ["qemu.kubernetes", "qemu.storage-ceph"]
    }
  }
}
