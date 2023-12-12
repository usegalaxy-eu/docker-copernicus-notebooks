# Jupyter container used for Galaxy copernicus notebooks (+other kernels) Integration

# from 5th March 2021
FROM jupyter/datascience-notebook:python-3.10

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

ENV DEBIAN_FRONTEND noninteractive
USER root

RUN apt-get -qq update && \
    apt-get install -y wget unzip net-tools procps && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set channels to (defaults) > bioconda > conda-forge
RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda
    #conda config --add channels defaults
RUN pip install --upgrade pip
RUN pip install --no-cache-dir bioblend galaxy-ie-helpers

ENV JUPYTER /opt/conda/bin/jupyter
ENV PYTHON /opt/conda/bin/python
ENV LD_LIBRARY_PATH /opt/conda/lib/

# Python packages
RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda install --yes --quiet \
    bash_kernel \
    ansible-kernel \
    bioblend galaxy-ie-helpers \
    # specific sentinel, openeo packages
    sentinelhub \
    openeo \
    # other packages for notebooks
    geopandas \
    rasterio \
    ipyleaflet \
    netcdf4 \
    h5netcdf \
    # Jupyter widgets
    jupytext && \
    conda clean -yt && \
    pip install jupyterlab_hdf \
    fusets
    
#RUN conda install -c pyviz holoviews bokeh
    
ADD ./startup.sh /startup.sh
ADD ./get_notebook.py /get_notebook.py

# We can get away with just creating this single file and Jupyter will create the rest of the
# profile for us.
RUN mkdir -p /home/$NB_USER/.ipython/profile_default/startup/ && \
    mkdir -p /home/$NB_USER/.jupyter/custom/

COPY ./ipython-profile.py /home/$NB_USER/.ipython/profile_default/startup/00-load.py
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
COPY jupyter_lab_config.py /home/$NB_USER/.jupyter/

ADD ./custom.js /home/$NB_USER/.jupyter/custom/custom.js
ADD ./custom.css /home/$NB_USER/.jupyter/custom/custom.css
ADD ./default_notebook.ipynb /home/$NB_USER/notebook.ipynb

# Download notebooks
RUN cd /home/$NB_USER/ &&  \
    wget -O notebook-samples.zip https://github.com/eu-cdse/notebook-samples/archive/refs/heads/main.zip && \
    unzip notebook-samples.zip && \
    rm /home/$NB_USER/notebook-samples.zip && \
    mv /home/$NB_USER/notebook-samples-main/geo /home/$NB_USER && \
    mv /home/$NB_USER/notebook-samples-main/sentinelhub /home/$NB_USER && \
    mv /home/$NB_USER/notebook-samples-main/openeo /home/$NB_USER && \
    rm -r /home/$NB_USER/notebook-samples-main

# ENV variables to replace conf file
ENV DEBUG=false \
    GALAXY_WEB_PORT=10000 \
    NOTEBOOK_PASSWORD=none \
    CORS_ORIGIN=none \
    DOCKER_PORT=none \
    API_KEY=none \
    HISTORY_ID=none \
    REMOTE_HOST=none \
    GALAXY_URL=none

# @jupyterlab/google-drive  not yet supported

USER root
WORKDIR /import

# Start Jupyter Notebook
CMD /startup.sh

