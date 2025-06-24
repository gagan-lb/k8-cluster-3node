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

## 📋 Prerequisites

### Target Servers (RHEL 9.4)
- **3 RHEL 9.4 servers** with the following minimum specifications:
  - **CPU**: 2 cores minimum
  - **Memory**: 2GB RAM minimum (4GB recommended)
  - **Storage**: 20GB available disk space
  - **Network**: All nodes must be able to communicate with each other
  - **User Access**: Root or sudo privileges on all servers

### Control Machine (Where you run the script)
- **Operating System**: 
  - macOS (with Homebrew)
  - Linux (RHEL, CentOS, Ubuntu, Debian, Arch)
- **Network Access**: SSH connectivity to all target servers
- **Internet Access**: Required for package downloads

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

# Ubuntu/Debian
sudo apt update && sudo apt install sshpass

# Arch Linux
sudo pacman -S sshpass
```

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

### Example Session

```
==========================================
  Kubernetes 3-Node Cluster Setup
==========================================

Controller Node Information:
Enter controller node hostname or IP address: 192.168.1.10
Enter username for controller node: root
Enter password for controller node: [hidden]

Worker Node 1 Information:
Enter worker node hostname or IP address: 192.168.1.11
Enter username for worker node 1: root
Enter password for worker node 1: [hidden]

Worker Node 2 Information:
Enter worker node hostname or IP address: 192.168.1.12
Enter username for worker node 2: root
Enter password for worker node 2: [hidden]

Collected Node Information:
Controller: root@192.168.1.10
Worker 1:   root@192.168.1.11
Worker 2:   root@192.168.1.12

Is this information correct? (y/n): y
```

## 🔧 What the Script Does

### Phase 1: Prerequisites Installation
- Disables SELinux and swap
- Loads required kernel modules (`overlay`, `br_netfilter`)
- Configures kernel parameters for Kubernetes
- Installs and configures containerd runtime
- Adds Kubernetes repository
- Installs `kubelet`, `kubeadm`, and `kubectl`
- Configures firewall settings

### Phase 2: SSH Authentication Setup
- Generates SSH key pair (if not exists)
- Copies public key to all target servers
- Establishes passwordless authentication
- Verifies SSH connectivity

### Phase 3: Cluster Initialization
- Initializes Kubernetes cluster on controller node
- Configures kubectl access for the user
- Installs Flannel CNI plugin for pod networking
- Generates join tokens for worker nodes

### Phase 4: Worker Node Setup
- Joins both worker nodes to the cluster
- Verifies node status and connectivity

### Phase 5: Verification
- Displays cluster status
- Shows all nodes and their status
- Lists running system pods

## 🌐 Network Configuration

The script configures the following network settings:

- **Pod Network CIDR**: `10.244.0.0/16` (Flannel default)
- **Service Network CIDR**: `10.96.0.0/12` (Kubernetes default)
- **CNI Plugin**: Flannel
- **Container Runtime**: containerd with systemd cgroup driver

## 🔒 Security Considerations

### SSH Security
- Generates 4096-bit RSA SSH keys
- Disables password authentication after key setup
- Uses `StrictHostKeyChecking=no` during initial setup (acceptable for new deployments)

### Cluster Security
- Firewall is disabled for simplicity (configure properly for production)
- SELinux is set to permissive mode
- Root access is used (consider creating dedicated Kubernetes user for production)

### Production Recommendations
- Enable firewall with specific Kubernetes port rules
- Use non-root users with appropriate sudo privileges
- Implement proper SELinux policies
- Configure TLS certificates for additional security
- Set up RBAC (Role-Based Access Control)

## 📁 File Locations

After successful installation, important files are located at:

### Controller Node
- **Kubernetes Config**: `~/.kube/config`
- **Admin Config**: `/etc/kubernetes/admin.conf`
- **Certificate Directory**: `/etc/kubernetes/pki/`

### All Nodes
- **Kubelet Config**: `/etc/kubernetes/kubelet.conf`
- **Containerd Config**: `/etc/containerd/config.toml`
- **Systemd Services**: `/etc/systemd/system/kubelet.service.d/`

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

## 🛠 Troubleshooting

### Common Issues

#### 1. SSH Connection Failed
```bash
# Solution: Verify network connectivity and credentials
ping <server-ip>
ssh -v root@<server-ip>
```

#### 2. Package Installation Failed
```bash
# Solution: Check internet connectivity and repository access
curl -I https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
```

#### 3. Node Not Ready
```bash
# Check node status and logs
kubectl get nodes
kubectl describe node <node-name>
sudo journalctl -u kubelet -f
```

#### 4. Pod Network Issues
```bash
# Check Flannel pods
kubectl get pods -n kube-flannel
kubectl logs -n kube-flannel <flannel-pod-name>
```

### Log Locations
- **Kubelet logs**: `sudo journalctl -u kubelet`
- **Containerd logs**: `sudo journalctl -u containerd`
- **System logs**: `/var/log/messages`

### Reset Cluster (if needed)
```bash
# On all nodes
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/
sudo rm -rf /var/lib/etcd/
```

## 🚦 Post-Installation Steps

### 1. Install Additional Tools
```bash
# Install Helm package manager
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl auto-completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
```

### 2. Deploy Sample Application
```bash
# Deploy nginx
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# Check deployment
kubectl get deployments
kubectl get services
```

### 3. Configure Storage (Optional)
```bash
# Install local-path-provisioner for dynamic storage
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
```

## 🔧 Customization

### Modify Pod Network CIDR
Edit the script and change:
```bash
# Line in initialize_cluster function
execute_remote "$host" "$user" "sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
```

### Use Different CNI Plugin
Replace Flannel installation with your preferred CNI:
```bash
# Instead of Flannel, use Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Add More Worker Nodes
Extend the script to support additional worker nodes by:
1. Adding more node information collection
2. Extending the worker joining loop
3. Updating verification steps

## 📞 Support

For issues and questions:
- **GitHub Issues**: [Report issues or request features](https://github.com/gagan-lb/k8-cluster-3node/issues)
- **Documentation**: Check the troubleshooting section above
- **Kubernetes Docs**: Review [Kubernetes official documentation](https://kubernetes.io/docs/)
- **RHEL Compatibility**: Check RHEL 9.4 compatibility notes
- **Network**: Verify network connectivity between nodes

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This script is provided as-is for educational and production use. Please review and test thoroughly before using in production environments.

## ⚠️ Important Notes

- **Backup**: Always backup important data before running cluster setup
- **Testing**: Test in a development environment first
- **Production**: Review security settings before production deployment
- **Updates**: Keep Kubernetes components updated regularly
- **Monitoring**: Implement proper monitoring and logging solutions

---

**Script Version**: 1.0  
**Kubernetes Version**: 1.28  
**Tested On**: RHEL 9.4, macOS, Ubuntu 22.04  
**Last Updated**: June 2025
