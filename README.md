# Kubernetes 3-Node Cluster Setup Script

An automated script to deploy a production-ready 3-node Kubernetes cluster on RHEL 9.4 servers with passwordless SSH authentication.

## 📦 Repository

**GitHub**: [https://github.com/gagan-lb/k8-cluster-3node](https://github.com/gagan-lb/k8-cluster-3node)

## 🚀 Overview

This script automates the complete setup of a Kubernetes cluster consisting of:
- **1 Controller Node** (Master node running the control plane)
- **2 Worker Nodes** (Compute nodes running workloads)

The script handles everything from initial server preparation to cluster verification, including:
- Passwordless SSH authentication setup
- Container runtime installation (containerd)
- Kubernetes components installation
- Cluster initialization and node joining
- Network plugin configuration (Flannel CNI)

## ⚡ Quick Start

```bash
# Clone the repository
git clone https://github.com/gagan-lb/k8-cluster-3node.git
cd k8-cluster-3node

# Make the script executable
chmod +x setup-k8s-cluster.sh

# Run the setup (requires sshpass - see installation section below)
./setup-k8s-cluster.sh
```

## 🛠 Installation

### Step 1: Download the Script

```bash
# Clone the repository
git clone https://github.com/gagan-lb/k8-cluster-3node.git
cd k8-cluster-3node

# OR download directly
wget https://raw.githubusercontent.com/gagan-lb/k8-cluster-3node/main/setup-k8s-cluster.sh
# OR
curl -O https://raw.githubusercontent.com/gagan-lb/k8-cluster-3node/main/setup-k8s-cluster.sh
```

### Step 2: Make it Executable

```bash
chmod +x setup-k8s-cluster.sh
```

### Step 3: Install Dependencies

#### On macOS:
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install sshpass
brew install hudochenkov/sshpass/sshpass
```

#### On Linux:
```bash
# RHEL/CentOS/Fedora
sudo dnf install sshpass


## 🚀 Usage

### Interactive Setup

1. **Run the script**:
```bash
./setup-k8s-cluster.sh
```

2. **Provide server information** when prompted:
   - Hostname or IP address for each node
   - Username (typically `root`)
   - Password for each server

3. **Confirm the information** and let the script run

## 🔍 Verification Commands

After installation, verify your cluster:

```bash
# SSH to controller node
ssh root@<controller-ip>

# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -A

# Check cluster info
kubectl cluster-info

# Check component status
kubectl get componentstatus

# Verify networking
kubectl get pods -n kube-flannel
```

