#!/bin/bash
#
# Setup for GitHub Runner server

set -euxo pipefail

#
# Install Runner
#

# Create a folder
mkdir actions-runner 
cd actions-runner
# Download the latest runner package
curl -o actions-runner-linux-x64-2.322.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-linux-x64-2.322.0.tar.gz
# Extract the installer
tar xzf ./actions-runner-linux-x64-2.322.0.tar.gz
chown -R vagrant:vagrant /home/vagrant/actions-runner 

#
# Configure Runner
#

# Create the runner and start the configuration experience
sudo -u vagrant ./config.sh --unattended --replace --url https://github.com/oldmxnk/k8s-vagrant --token BGB5O5SVAVF2LQ6U26V3FQLHY5JV2
# Last step, install service and start it
sudo ./svc.sh install vagrant
sudo ./svc.sh start

#
# Install ArgoCD CLI
#
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

#
# Setup K8s config on server
#

config_path="/vagrant/configs"
sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF
