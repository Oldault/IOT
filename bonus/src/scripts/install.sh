#!/bin/bash

set -e

CLUSTER_NAME=svolodin

echo "Checking for existing k3d cluster '$CLUSTER_NAME'..."
if k3d cluster list | grep -q "^$CLUSTER_NAME "; then
    echo "✓ Cluster '$CLUSTER_NAME' already exists (from p3). Using existing cluster..."
    echo "Note: This is expected - bonus builds on top of p3's cluster setup."
else
    echo "⚠ Cluster '$CLUSTER_NAME' not found!"
    echo ""
    echo "The bonus setup requires the p3 cluster to exist first."
    echo "Please run the following first:"
    echo "  cd ../p3 && make all"
    echo ""
    exit 1
fi

echo "Cluster '$CLUSTER_NAME' is ready for GitLab installation!"