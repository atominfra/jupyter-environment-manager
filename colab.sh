#!/bin/bash

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
    if [ ! -f "$project_name/docker-compose.yaml" ]; then
        echo "Error: Docker Compose file for project '$project_name' not found."
        return 1
    fi
}

# Helper function to run Docker Compose commands
function run_docker_compose() {
    local project_name=$1
    local action=$2

    docker-compose -f "$project_name/docker-compose.yaml" $action
    if [ $? -ne 0 ]; then
        echo "Error: Failed to execute 'docker-compose $action' for project '$project_name'."
        return 1
    fi
}

# Function to check if a directory is a valid colab environment
function is_valid_env() {
    local dir=$1
    if [ -f "$dir/.colab_env" ]; then
        return 0  # True: This is a valid colab environment
    else
        return 1  # False: This is not a valid colab environment
    fi
}

# Function to list all environments
function list_envs() {
    echo "Available environments:"
    for dir in */ ; do
        [ -d "$dir" ] && is_valid_env "$dir" && echo "${dir%/}"
    done
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

    # Create a new directory for the project environment
    mkdir -p "$project_name" || { echo "Error: Failed to create directory '$project_name'."; return 1; }

    # Generate the docker-compose file and add other necessary files
    sed "s/PROJECT_NAME/${project_name}/g" docker-compose.yaml.template > "$project_name/docker-compose.yaml"
    cp Dockerfile "$project_name"
    cp jupyter_notebook_config.py "$project_name"
    cp entrypoint.sh "$project_name" || { echo "Error: Failed to create files for project '$project_name'."; return 1; }

    # Create the environment identifier file
    touch "$project_name/.colab_env"

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

    # Check if this is a valid environment
    is_valid_env "$project_name" || { echo "Error: '$project_name' is not a valid environment."; return 1; }

    # Stop the Docker environment and remove the directory
    run_docker_compose "$project_name" "down" || return 1
    rm -rf "$project_name" || { echo "Error: Failed to remove directory '$project_name'."; return 1; }

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

    # Check if this is a valid environment
    is_valid_env "$project_name" || { echo "Error: '$project_name' is not a valid environment."; return 1; }

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

    # Check if this is a valid environment
    is_valid_env "$project_name" || { echo "Error: '$project_name' is not a valid environment."; return 1; }

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

    # Validate project name
    validate_project_name "$project_name" || return 1

    # Check if this is a valid environment
    is_valid_env "$project_name" || { echo "Error: '$project_name' is not a valid environment."; return 1; }

    # Create a compressed archive of the environment
    tar -cJf "${project_name}.tar.xz" "$project_name" || { echo "Error: Failed to compress environment '$project_name'."; return 1; }
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
    tar -xJf "$archive_name" || { echo "Error: Failed to decompress archive '$archive_name'."; return 1; }
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