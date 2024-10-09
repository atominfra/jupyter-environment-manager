FROM python:3.10

# Install dependencies needed to create a virtual environment
RUN apt-get update && apt-get install -y python3-venv

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Copy the jupyter notebook configuration file
COPY jupyter_notebook_config.py /jupyter_notebook_config.py

# Set the entrypoint script to run on container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Expose the Jupyter port
EXPOSE 8888

# Set the PATH to use the virtual environment as the default python environment
ENV PATH="/opt/venv/bin:$PATH"
