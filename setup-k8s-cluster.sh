#!/bin/bash

# Kubernetes 3-Node Cluster Setup Script for RHEL 9.4
# This script sets up a 3-node Kubernetes cluster with passwordless SSH authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate hostname
validate_hostname() {
    local hostname=$1
    if [[ $hostname =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to collect node information
collect_node_info() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  Kubernetes 3-Node Cluster Setup${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo

    # Controller node information
    echo -e "${YELLOW}Controller Node Information:${NC}"
    while true; do
        read -p "Enter controller node hostname or IP address: " CONTROLLER_HOST
        if validate_ip "$CONTROLLER_HOST" || validate_hostname "$CONTROLLER_HOST"; then
            break
        else
            error "Invalid hostname or IP address. Please try again."
        fi
    done

    read -p "Enter username for controller node: " CONTROLLER_USER
    read -s -p "Enter password for controller node: " CONTROLLER_PASS
    echo

    # Worker node 1 information
    echo -e "${YELLOW}Worker Node 1 Information:${NC}"
    while true; do
        read -p "Enter worker node 1 hostname or IP address: " WORKER1_HOST
        if validate_ip "$WORKER1_HOST" || validate_hostname "$WORKER1_HOST"; then
            break
        else
            error "Invalid hostname or IP address. Please try again."
        fi
    done

    read -p "Enter username for worker node 1: " WORKER1_USER
    read -s -p "Enter password for worker node 1: " WORKER1_PASS
    echo

    # Worker node 2 information
    echo -e "${YELLOW}Worker Node 2 Information:${NC}"
    while true; do
        read -p "Enter worker node 2 hostname or IP address: " WORKER2_HOST
        if validate_ip "$WORKER2_HOST" || validate_hostname "$WORKER2_HOST"; then
            break
        else
            error "Invalid hostname or IP address. Please try again."
        fi
    done

    read -p "Enter username for worker node 2: " WORKER2_USER
    read -s -p "Enter password for worker node 2: " WORKER2_PASS
    echo
    echo

    # Display collected information for confirmation
    echo -e "${BLUE}Collected Node Information:${NC}"
    echo "Controller: $CONTROLLER_USER@$CONTROLLER_HOST"
    echo "Worker 1:   $WORKER1_USER@$WORKER1_HOST"
    echo "Worker 2:   $WORKER2_USER@$WORKER2_HOST"
    echo

    read -p "Is this information correct? (y/n): " CONFIRM
    if [[ $CONFIRM != [yY] ]]; then
        error "Setup cancelled by user."
        exit 1
    fi
}

# Function to install sshpass if not available
install_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        log "Installing sshpass..."
        if command -v dnf &> /dev/null; then
            sudo dnf install -y sshpass
        elif command -v yum &> /dev/null; then
            sudo yum install -y sshpass
        else
            error "Package manager not found. Please install sshpass manually."
            exit 1
        fi
    fi
}

# Function to generate SSH key if it doesn't exist
generate_ssh_key() {
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        log "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    else
        info "SSH key already exists."
    fi
}

# Function to copy SSH key to remote host
copy_ssh_key() {
    local host=$1
    local user=$2
    local pass=$3

    log "Setting up passwordless authentication for $user@$host..."
    
    # Copy SSH key using sshpass
    sshpass -p "$pass" ssh-copy-id -o StrictHostKeyChecking=no "$user@$host" 2>/dev/null || {
        error "Failed to copy SSH key to $user@$host"
        return 1
    }
    
    # Test SSH connection
    if ssh -o StrictHostKeyChecking=no "$user@$host" "echo 'SSH connection successful'" &>/dev/null; then
        log "Passwordless authentication set up successfully for $user@$host"
    else
        error "Failed to establish SSH connection to $user@$host"
        return 1
    fi
}

# Function to execute command on remote host
execute_remote() {
    local host=$1
    local user=$2
    local command=$3
    
    ssh -o StrictHostKeyChecking=no "$user@$host" "$command"
}

# Function to install Docker and Kubernetes prerequisites
install_prerequisites() {
    local host=$1
    local user=$2
    local node_type=$3

    log "Installing prerequisites on $node_type ($user@$host)..."

    # Create the installation script
    cat << 'EOF' > /tmp/k8s_prereq.sh
#!/bin/bash

# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Disable swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Load kernel modules
cat <<EOL | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOL

sudo modprobe overlay
sudo modprobe br_netfilter

# Set kernel parameters
cat <<EOL | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOL

sudo sysctl --system

# Install containerd
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Enable and start containerd
sudo systemctl enable --now containerd

# Add Kubernetes repository
cat <<EOL | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOL

# Install Kubernetes components
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Enable kubelet
sudo systemctl enable --now kubelet

# Configure firewall
sudo systemctl stop firewalld
sudo systemctl disable firewalld

echo "Prerequisites installation completed successfully!"
EOF

    # Copy and execute the script
    scp /tmp/k8s_prereq.sh "$user@$host:/tmp/"
    execute_remote "$host" "$user" "chmod +x /tmp/k8s_prereq.sh && /tmp/k8s_prereq.sh"
    
    rm -f /tmp/k8s_prereq.sh
}

# Function to initialize Kubernetes cluster
initialize_cluster() {
    local host=$1
    local user=$2

    log "Initializing Kubernetes cluster on controller node..."

    # Initialize the cluster
    execute_remote "$host" "$user" "sudo kubeadm init --pod-network-cidr=10.244.0.0/16"

    # Set up kubectl for the user
    execute_remote "$host" "$user" "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config && sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"

    # Install Flannel CNI
    execute_remote "$host" "$user" "kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"

    # Get join command
    JOIN_COMMAND=$(execute_remote "$host" "$user" "sudo kubeadm token create --print-join-command")
    
    log "Cluster initialized successfully!"
    info "Join command: $JOIN_COMMAND"
}

# Function to join worker node to cluster
join_worker() {
    local host=$1
    local user=$2
    local node_name=$3

    log "Joining $node_name to the cluster..."
    
    execute_remote "$host" "$user" "sudo $JOIN_COMMAND"
    
    log "$node_name joined the cluster successfully!"
}

# Function to verify cluster status
verify_cluster() {
    local host=$1
    local user=$2

    log "Verifying cluster status..."
    
    sleep 30  # Wait for nodes to be ready
    
    execute_remote "$host" "$user" "kubectl get nodes -o wide"
    execute_remote "$host" "$user" "kubectl get pods -A"
}

# Main execution
main() {
    log "Starting Kubernetes 3-node cluster setup..."

    # Collect node information
    collect_node_info

    # Install sshpass if needed
    install_sshpass

    # Generate SSH key
    generate_ssh_key

    # Set up passwordless authentication
    copy_ssh_key "$CONTROLLER_HOST" "$CONTROLLER_USER" "$CONTROLLER_PASS"
    copy_ssh_key "$WORKER1_HOST" "$WORKER1_USER" "$WORKER1_PASS"
    copy_ssh_key "$WORKER2_HOST" "$WORKER2_USER" "$WORKER2_PASS"

    # Install prerequisites on all nodes
    install_prerequisites "$CONTROLLER_HOST" "$CONTROLLER_USER" "Controller Node"
    install_prerequisites "$WORKER1_HOST" "$WORKER1_USER" "Worker Node 1"
    install_prerequisites "$WORKER2_HOST" "$WORKER2_USER" "Worker Node 2"

    # Initialize cluster on controller node
    initialize_cluster "$CONTROLLER_HOST" "$CONTROLLER_USER"

    # Join worker nodes to cluster
    join_worker "$WORKER1_HOST" "$WORKER1_USER" "Worker Node 1"
    join_worker "$WORKER2_HOST" "$WORKER2_USER" "Worker Node 2"

    # Verify cluster status
    verify_cluster "$CONTROLLER_HOST" "$CONTROLLER_USER"

    log "Kubernetes cluster setup completed successfully!"
    echo
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${GREEN}  Cluster Setup Complete!${NC}"
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${BLUE}Controller Node: $CONTROLLER_USER@$CONTROLLER_HOST${NC}"
    echo -e "${BLUE}Worker Node 1:   $WORKER1_USER@$WORKER1_HOST${NC}"
    echo -e "${BLUE}Worker Node 2:   $WORKER2_USER@$WORKER2_HOST${NC}"
    echo
    echo -e "${YELLOW}To access your cluster, SSH to the controller node and use kubectl:${NC}"
    echo -e "${YELLOW}ssh $CONTROLLER_USER@$CONTROLLER_HOST${NC}"
    echo -e "${YELLOW}kubectl get nodes${NC}"
}

# Run main function
main "$@"
