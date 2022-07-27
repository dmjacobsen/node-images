#!/bin/bash
podman rmi --all

podman image load -i /srv/cray/resources/common/images/registry_2.8.1.tar

mkdir -p /var/lib/registry

if  ! systemctl is-active registry.container.service
then
  systemctl enable registry.container.service
  systemctl start registry.container.service
fi


image_path="/srv/cray/resources/common/images/"
echo "Pre-loading local images"

podman image load -i /srv/cray/resources/common/images/ceph_v16.2.7.tar
podman image load -i /srv/cray/resources/common/images/ceph_v16.2.9.tar
podman image load -i /srv/cray/resources/common/images/ceph_v15.2.15.tar
podman image load -i /srv/cray/resources/common/images/ceph_v15.2.16.tar
podman tag  registry.local/ceph/ceph:v15.2.16 registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.16
podman tag  registry.local/ceph/ceph:v15.2.16 registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.16
podman tag  registry.local/ceph/ceph:v15.2.15 artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
podman tag  registry.local/ceph/ceph:v15.2.16 artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.16
podman tag  registry.local/ceph/ceph:v16.2.7 artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v16.2.7
podman tag  registry.local/ceph/ceph:v16.2.9 artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v16.2.9
podman tag  registry.local/ceph/ceph:v15.2.16 localhost:5000/ceph/ceph:v15.2.16
podman tag  registry.local/ceph/ceph:v15.2.15 localhost:5000/ceph/ceph:v15.2.15
podman tag  registry.local/ceph/ceph:v16.2.7 localhost:5000/ceph/ceph:v16.2.7
podman tag  registry.local/ceph/ceph:v16.2.9 localhost:5000/ceph/ceph:v16.2.9

podman image load -i /srv/cray/resources/common/images/ceph-grafana_8.3.5.tar
podman tag registry.local/ceph/ceph-grafana:8.3.5 registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph-grafana:8.3.5
podman tag registry.local/ceph/ceph-grafana:8.3.5 artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph-grafana:8.3.5
podman tag registry.local/ceph/ceph-grafana:8.3.5 registry.local/quay.io/ceph/ceph-grafana:8.3.5
podman tag registry.local/ceph/ceph-grafana:8.3.5 localhost:5000/ceph/ceph-grafana:8.3.5

podman image load -i /srv/cray/resources/common/images/ceph-grafana_6.7.4.tar

podman image load -i /srv/cray/resources/common/images/prometheus_v2.18.1.tar
podman tag registry.local/prometheus/prometheus:v2.18.1  artifactory.algol60.net/csm-docker/stable/prometheus/prometheus:v2.18.1
podman tag registry.local/prometheus/prometheus:v2.18.1  localhost:5000/prometheus/prometheus:v2.18.1
podman tag registry.local/prometheus/prometheus:v2.18.1  localhost:5000/quay.io/prometheus/prometheus:v2.18.1
podman tag registry.local/prometheus/prometheus:v2.18.1  registry.local/quay.io/prometheus/prometheus:v2.18.1

podman image load -i /srv/cray/resources/common/images/alertmanager_v0.20.0.tar
podman tag registry.local/prometheus/alertmanager:v0.20.0 localhost:5000/quay.io/prometheus/alertmanager:v0.20.0
podman tag registry.local/prometheus/alertmanager:v0.20.0 localhost:5000/prometheus/alertmanager:v0.20.0

podman image load -i /srv/cray/resources/common/images/alertmanager_v0.21.0.tar
podman tag registry.local/prometheus/alertmanager:v0.21.0 registry.local/quay.io/prometheus/alertmanager:v0.21.0
podman tag registry.local/prometheus/alertmanager:v0.21.0 localhost:5000/prometheus/alertmanager:v0.21.0
podman tag registry.local/prometheus/alertmanager:v0.21.0 localhost:5000/quay.io/prometheus/alertmanager:v0.21.0
podman tag registry.local/prometheus/alertmanager:v0.21.0 artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/alertmanager:v0.21.0

podman image load -i /srv/cray/resources/common/images/node-exporter_v1.2.2.tar
podman tag registry.local/prometheus/node-exporter:v1.2.2 registry.local/quay.io/prometheus/node-exporter:v1.2.2
podman tag registry.local/prometheus/node-exporter:v1.2.2 localhost:5000/prometheus/node-exporter:v1.2.2
podman tag registry.local/prometheus/node-exporter:v1.2.2 localhost:5000/quay.io/prometheus/node-exporter:v1.2.2
podman tag registry.local/prometheus/node-exporter:v1.2.2 artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/node-exporter:v1.2.2


podman push localhost:5000/ceph/ceph:v15.2.15
podman push localhost:5000/ceph/ceph:v15.2.16
podman push localhost:5000/ceph/ceph-grafana:8.3.5
podman push localhost:5000/ceph/ceph:v16.2.7
podman push localhost:5000/ceph/ceph:v16.2.9
podman push localhost:5000/prometheus/node-exporter:v1.2.2
podman push localhost:5000/quay.io/prometheus/node-exporter:v1.2.2
podman push localhost:5000/prometheus/alertmanager:v0.21.0
podman push localhost:5000/quay.io/prometheus/alertmanager:v0.21.0
podman push localhost:5000/prometheus/prometheus:v2.18.1
podman push localhost:5000/quay.io/prometheus/prometheus:v2.18.1
podman push localhost:5000/prometheus/alertmanager:v0.20.0

echo "Images loaded"
