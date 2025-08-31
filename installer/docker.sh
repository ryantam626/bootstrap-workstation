#!/bin/bash

set -euxo pipefail

curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
