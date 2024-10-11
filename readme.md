
# Jupyter Environment Manager

This script provides a command-line interface for managing Jupyter environments using Docker. You can create, start, stop, delete, export, and import environments with ease.

## Instructions

### Create an Environment

To create a new environment, use the following command:

```bash
./colab.sh create_env <env-name>
```

**Example:**

```bash
./colab.sh create_env myenvironment
```

### Access an Environment

To access Jupyter Notebook, open a web browser and go to:

```
http://<env-name>.jupyter.localdev.me
```

### Delete an Environment

To delete an existing environment, use this command:

```bash
./colab.sh delete_env <env-name>
```

**Example:**

```bash
./colab.sh delete_env myenvironment
```

### Start an Environment

To start a stopped environment, run:

```bash
./colab.sh start_env <env-name>
```

**Example:**

```bash
./colab.sh start_env myenvironment
```

### Stop an Environment

To stop a running environment, use the following command:

```bash
./colab.sh stop_env <env-name>
```

**Example:**

```bash
./colab.sh stop_env myenvironment
```

### Export an Environment

To export an environment to a compressed archive, use this command:

```bash
./colab.sh export_env <env-name>
```

**Example:**

```bash
./colab.sh export_env myenvironment
```

This will create a file named `myenvironment.tar.xz`.

### Import an Environment

To import an environment from a compressed archive, use:

```bash
./colab.sh import_env <archive-name>
```

**Example:**

```bash
./colab.sh import_env myenvironment.tar.xz
```

### List All Environments

To list all available environments, run:

```bash
./colab.sh list_envs
```

This will display all environments created using this script.

## Notes

- Ensure that the project names conform to Docker Compose service name standards:
  - Start with a lowercase letter or digit
  - Contain only lowercase letters, digits, and hyphens
  - End with a lowercase letter or digit
  - Be at most 63 characters long
