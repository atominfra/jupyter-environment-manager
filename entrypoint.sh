#!/bin/bash

# Check if the virtual environment directory is empty
if [ -z "$(ls -A /opt/venv)" ]; then
    echo "Initializing virtual environment..."
    python3 -m venv /opt/venv
    # Install Jupyter (or any other dependencies you need)
    /opt/venv/bin/pip install jupyter
fi

# Copy the Jupyter configuration file
jupyter notebook --generate-config
cp /jupyter_notebook_config.py /root/.jupyter/jupyter_notebook_config.py

# Start Jupyter
exec jupyter notebook --ip=0.0.0.0 --allow-root --no-browser
