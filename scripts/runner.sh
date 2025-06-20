#!/bin/bash
#
# Setup for GitHub Runner server

set -euxo pipefail

# Variables
REPO_URL="https://github.com/oldmxnk/k8s-vagrant"
API_URL="https://api.github.com/repos/oldmxnk/k8s-vagrant"

GITHUB_TOKEN=""

RUNNER_NAME="self-hosted-k8s-runner"
RUNNER_LABELS="self-hosted,Linux,K8s"

# Install dependencies
sudo apt-get install -y curl jq

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
rm -f ./actions-runner-linux-x64-2.322.0.tar.gz

# Get the runner token from GitHub
RUNNER_TOKEN=$(curl -X POST -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "$API_URL/actions/runners/registration-token" | jq -e -r .token)

#
# Configure Runner
#

# Create the runner and start the configuration experience
sudo -u vagrant ./config.sh --unattended --replace --url $REPO_URL --token $RUNNER_TOKEN --name $RUNNER_NAME --labels $RUNNER_LABELS

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

#
# Install Helm
#

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
