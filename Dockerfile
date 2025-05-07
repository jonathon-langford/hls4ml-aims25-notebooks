#Build:
#docker build -t oneapi-hls4ml-2025 --build-arg user=$USER .
#Run:
#docker run -p 127.0.0.1:8080:8080 -v /home/$USER/:/home/$USER/local -it oneapi-hls4ml-2025

# Inside the container:
# source /opt/intel/oneapi/2025.0/oneapi-vars.sh --force
# source /opt/intel/oneapi/2025.0/opt/oclfpga/fpgavars.sh --force
# jupyter notebook --port=8080 --ip=0.0.0.0 --no-browser

FROM intel/oneapi-basekit:2025.0.1-0-devel-ubuntu24.04

ARG user=jupyter

SHELL ["/bin/bash", "-c"]
# Install wget to fetch Mini-forge
RUN apt-get update && \
    apt-get install -y wget && \
    apt update && \
    apt install -y intel-oneapi-compiler-fpga && \
    apt-get clean
  
RUN userdel ubuntu
RUN useradd -m $user -s /bin/bash

USER $user

ENV PATH="/home/$user/miniconda3/bin:$PATH"

RUN MINICONDA_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"; \
    cd ;\
    pwd ; \
    wget $MINICONDA_URL -O miniconda.sh && \
    mkdir -p /home/$user/.conda && \
    bash miniconda.sh -b -p /home/$user/miniconda3 && \
    rm -f miniconda.sh


# Change SHELL so that RUN commands are run inside conda base env
SHELL ["conda", "run", "--no-capture-output", "-n", "base", "/bin/bash", "-c"]

# Create conda envs and install
RUN conda create -n oneapi-env python=3.10 -y \
    && conda run -n oneapi-env pip install numpy==1.26.4 \
    && conda run -n oneapi-env pip install tensorflow==2.14.0 \
    && conda run -n oneapi-env conda install jupyter \
    && conda run -n oneapi-env pip install matplotlib \
    && conda run -n oneapi-env pip install scikit-learn \
    && conda run -n oneapi-env pip install ndjson \
    && conda run -n oneapi-env pip install git+https://github.com/fastmachinelearning/hls4ml \
    && conda run -n oneapi-env pip install git+https://github.com/fastmachinelearning/qkeras \
    && conda run -n oneapi-env pip install pyparsing \
    && conda run -n oneapi-env pip install pytest \
    && conda run -n oneapi-env conda install -c conda-forge libstdcxx-ng \
    && conda init bash

RUN echo "conda activate oneapi-env" >> ~/.bashrc
# Automatically source Intel environment variables when starting a shell
RUN echo "source /opt/intel/oneapi/2025.0/oneapi-vars.sh --force" >> /home/$user/.bashrc
RUN echo "source /opt/intel/oneapi/2025.0/opt/oclfpga/fpgavars.sh --force" >> /home/$user/.bashrc

CMD ["/bin/bash"]

EXPOSE 8080
