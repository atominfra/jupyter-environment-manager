#!/bin/bash

install_docker_and_compose() {
    # Function to check if a command exists
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    # Detect the OS distribution
    get_distro() {
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "macos"
        elif [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        else
            echo "unsupported"
        fi
    }

    # Install Docker and Docker Compose on Debian/Ubuntu-based distros
    install_docker_debian() {
        echo "Installing Docker for Debian/Ubuntu..."
        
        # Remove old versions of Docker if any
        sudo apt-get remove -y docker docker-engine docker.io containerd runc

        # Install required packages
        sudo apt-get update
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release

        # Add Docker’s official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # Set up the stable Docker repository
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Enable and start Docker
        sudo systemctl enable docker
        sudo systemctl start docker

        # Add the current user to the Docker group
        sudo usermod -aG docker "$USER"
        
        # Reflect the changes in the current shell
        newgrp docker
        
        echo "Docker installed successfully for Debian/Ubuntu."
    }

    # Install Docker and Docker Compose on Fedora/CentOS-based distros
    install_docker_fedora() {
        echo "Installing Docker for Fedora/CentOS..."
        
        # Remove old versions of Docker if any
        sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine

        # Install required packages
        sudo dnf install -y dnf-plugins-core

        # Set up the Docker repository
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

        # Install Docker Engine
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Enable and start Docker
        sudo systemctl enable docker
        sudo systemctl start docker

        # Add the current user to the Docker group
        sudo usermod -aG docker "$USER"
        
        # Reflect the changes in the current shell
        newgrp docker
        
        echo "Docker installed successfully for Fedora/CentOS."
    }

    # Install Docker and Docker Compose on macOS
    install_docker_macos() {
        echo "Installing Docker for macOS..."

        # Check if Homebrew is installed
        if ! command_exists brew; then
            echo "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        # Install Docker using Homebrew
        brew install --cask docker

        # Start Docker (open the Docker app)
        open -a Docker

        echo "Docker installed successfully for macOS."
    }

    # Install Docker Compose (works for all distros except macOS)
    install_docker_compose() {
        echo "Installing Docker Compose..."

        # Install the latest version of Docker Compose
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
        sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

        # Make the Docker Compose binary executable
        sudo chmod +x /usr/local/bin/docker-compose

        echo "Docker Compose installed successfully."
    }

    # Main logic to detect the OS and install Docker accordingly
    distro=$(get_distro)

    case "$distro" in
        ubuntu|debian)
            if command_exists docker; then
                echo "Docker is already installed."
            else
                install_docker_debian
            fi
            ;;
        fedora|centos|rhel)
            if command_exists docker; then
                echo "Docker is already installed."
            else
                install_docker_fedora
            fi
            ;;
        macos)
            if command_exists docker; then
                echo "Docker is already installed."
            else
                install_docker_macos
            fi
            ;;
        *)
            echo "Your distribution is not supported by this script."
            return 1
            ;;
    esac

    # Check if Docker Compose is installed (on Linux only)
    if [[ "$distro" != "macos" ]]; then
        if command_exists docker-compose; then
            echo "Docker Compose is already installed."
        else
            install_docker_compose
        fi
    else
        echo "Docker Compose is included in the Docker Desktop installation on macOS."
    fi

    # Verify installation
    docker --version
    if [[ "$distro" != "macos" ]]; then
        docker-compose --version
    fi
}

install_docker_and_compose
