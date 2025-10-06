#!/bin/sh

curl -s https://get.docker.com | sh

sudo usermod -aG docker $USER

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash