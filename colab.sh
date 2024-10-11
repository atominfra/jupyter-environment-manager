#!/bin/bash

source install_docker.sh

# Check if the Docker network called "colab" exists
if ! docker network ls | grep -q 'colab'; then
    # Create the Docker network if it does not exist
    docker network create colab
    echo "Docker network 'colab' created."
else
    echo "Docker network 'colab' already exists."
fi

# Define projects directory
PROJECTS_DIR="$HOME/.jupyter-project-manager/projects"

# Helper function to validate project name
function validate_project_name() {
    local project_name=$1
    if ! [[ "$project_name" =~ ^[a-z0-9][a-z0-9-]{0,62}[a-z0-9]$ ]]; then
        echo "Error: Invalid project name '$project_name'."
        echo "Project name must:"
        echo "  - Start with a lowercase letter or digit"
        echo "  - Contain only lowercase letters, digits, and hyphens"
        echo "  - End with a lowercase letter or digit"
        echo "  - Be at most 63 characters long"
        return 1
    fi
}

# Helper function to check for Docker Compose file
function check_docker_compose_file() {
    local project_name=$1
    if [ ! -f "$PROJECTS_DIR/$project_name/docker-compose.yaml" ]; then
        echo "Error: Docker Compose file for project '$project_name' not found."
        return 1
    fi
}

function run_docker() {
    if ! docker ps >/dev/null 2>&1; then
        echo "You might not have permission to run Docker commands without sudo."
        echo "Attempting to run with sudo..."
        SUDO="sudo"  # Use sudo if Docker command fails
    else
        SUDO=""  # No sudo needed
    fi

    $SUDO docker "$@"     
}

# Helper function to run Docker Compose commands with permission handling
function run_docker_compose() {
    local project_name=$1
    local action=$2

    # Try running a simple Docker command to check for permission
    if ! docker ps >/dev/null 2>&1; then
        echo "You might not have permission to run Docker commands without sudo."
        echo "Attempting to run with sudo..."
        SUDO="sudo"  # Use sudo if Docker command fails
    else
        SUDO=""  # No sudo needed
    fi

    # Attempt to run the docker-compose command
    $SUDO docker-compose -f "$PROJECTS_DIR/$project_name/docker-compose.yaml" $action
    if [ $? -ne 0 ]; then
        echo "Error: Failed to execute 'docker-compose $action' for project '$project_name'."
        return 1
    fi
}

# Function to list all environments
function list_envs() {
    echo "Available environments:"
    run_docker ps --filter "label=com.docker.compose.project.namespace=colab" --format "{{.Label \"com.docker.compose.project\"}}"
}

# Function to create an environment
function create_env() {
    local project_name=$1

    if [ -z "$project_name" ]; then
        echo "Error: No project name provided."
        echo "Usage: colab.sh create_env <project_name>"
        return 1
    fi

    # Validate project name
    validate_project_name "$project_name" || return 1

    # Check if template file exists
    if [ ! -f "docker-compose.yaml.template" ]; then
        echo "Error: Template file 'docker-compose.yaml.template' not found."
        return 1
    fi

    # Create projects directory if it doesn't exist
    mkdir -p "$PROJECTS_DIR" || { echo "Error: Failed to create projects directory."; return 1; }

    # Create a new directory for the project environment
    mkdir -p "$PROJECTS_DIR/$project_name" || { echo "Error: Failed to create directory '$project_name'."; return 1; }

    # Generate the docker-compose file and add other necessary files
    sed "s/PROJECT_NAME/${project_name}/g" docker-compose.yaml.template > "$PROJECTS_DIR/$project_name/docker-compose.yaml"
    cp Dockerfile "$PROJECTS_DIR/$project_name"
    cp jupyter_notebook_config.py "$PROJECTS_DIR/$project_name"
    cp entrypoint.sh "$PROJECTS_DIR/$project_name" || { echo "Error: Failed to create files for project '$project_name'."; return 1; }

    # Start the Docker environment
    run_docker_compose "$project_name" "up -d" || return 1

    echo "Environment created successfully for project '$project_name'."
}

# Function to delete an environment
function delete_env() {
    local project_name=$1

    if [ -z "$project_name" ]; then
        echo "Error: No project name provided."
        echo "Usage: colab.sh delete_env <project_name>"
        return 1
    fi

    # Validate project name
    validate_project_name "$project_name" || return 1

    # Stop the Docker environment and remove the directory
    run_docker_compose "$project_name" "down" || return 1
    rm -rf "$PROJECTS_DIR/$project_name" || { echo "Error: Failed to remove directory '$project_name'."; return 1; }

    echo "Environment for project '$project_name' deleted successfully."
}

# Function to start an environment
function start_env() {
    local project_name=$1

    if [ -z "$project_name" ]; then
        echo "Error: No project name provided."
        echo "Usage: colab.sh start_env <project_name>"
        return 1
    fi

    # Validate project name
    validate_project_name "$project_name" || return 1

    # Start the Docker environment
    run_docker_compose "$project_name" "up -d" || return 1

    echo "Environment for project '$project_name' started successfully."
}

# Function to stop an environment
function stop_env() {
    local project_name=$1

    if [ -z "$project_name" ]; then
        echo "Error: No project name provided."
        echo "Usage: colab.sh stop_env <project_name>"
        return 1
    fi

    # Validate project name
    validate_project_name "$project_name" || return 1

    # Stop the Docker environment
    run_docker_compose "$project_name" "down" || return 1

    echo "Environment for project '$project_name' stopped successfully."
}

# Function to export an environment
function export_env() {
    local project_name=$1

    if [ -z "$project_name" ]; then
        echo "Error: No project name provided."
        echo "Usage: colab.sh export_env <project_name>"
        return 1
    fi

    # Validate project name (you can define your own logic in this function)
    validate_project_name "$project_name" || return 1

    # Check if the project folder exists and is a directory
    if [ ! -d "$PROJECTS_DIR/$project_name" ]; then
        echo "Error: Project folder '$PROJECTS_DIR/$project_name' does not exist or is not a directory."
        return 1
    fi

    # Create a compressed archive of the environment
    tar -cJf "${project_name}.tar.xz" -C "$PROJECTS_DIR" "$project_name" || { echo "Error: Failed to compress environment '$project_name'."; return 1; }
    echo "Environment '$project_name' exported successfully to '${project_name}.tar.xz'."
}


# Function to import an environment
function import_env() {
    local archive_name=$1

    if [ -z "$archive_name" ]; then
        echo "Error: No archive name provided."
        echo "Usage: colab.sh import_env <archive_name>"
        return 1
    fi

    # Check if the archive exists
    if [ ! -f "$archive_name" ]; then
        echo "Error: Archive file '$archive_name' not found."
        return 1
    fi

    # Extract the archive
    tar -xJf "$archive_name" -C "$PROJECTS_DIR" || { echo "Error: Failed to decompress archive '$archive_name'."; return 1; }
    local project_name=$(basename "$archive_name" .tar.xz)

    echo "Environment '$project_name' imported successfully."
}

# CLI Handling
function main() {
    if [ -z "$1" ]; then
        echo "Error: No function name provided."
        echo "Usage: colab.sh <function_name> [arguments...]"
        return 1
    fi

    # Capture the function name and shift arguments
    local func=$1
    shift

    # Handle function execution
    case "$func" in
        create_env)
            create_env "$@"
            ;;
        delete_env)
            delete_env "$@"
            ;;
        start_env)
            start_env "$@"
            ;;
        stop_env)
            stop_env "$@"
            ;;
        export_env)
            export_env "$@"
            ;;
        import_env)
            import_env "$@"
            ;;
        list_envs)
            list_envs
            ;;
        *)
            echo "Error: Unknown function name '$func'."
            echo "Available functions: create_env, delete_env, start_env, stop_env, export_env, import_env, list_envs"
            return 1
            ;;
    esac
}

# Entry point for the script
main "$@"
