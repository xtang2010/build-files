# fast_float

**NOTE**: QNX ports are only supported from a Linux host operating system

Use `$(nproc)` instead of `4` after `JLEVEL=` if you want to use the maximum number of cores to build this project.

# Compile the port for QNX in a Docker container

Pre-requisite: Install Docker on Ubuntu https://docs.docker.com/engine/install/ubuntu/
```bash
# Create a workspace
mkdir -p ~/qnx_workspace && cd ~/qnx_workspace
git clone https://github.com/xtang2010/build-files.git

# Build the Docker image and create a container
cd build-files/docker
./docker-build-qnx-image.sh
./docker-create-container.sh

# source qnxsdp-env.sh in
source ~/qnx800/qnxsdp-env.sh

# Clone libevent
cd ~/qnx_workspace
git clone https://github.com/fastfloat/fast_float.git
git switch v8.2.2

# Build libevent
cd ~/qnx_workspace/build-files/ports/fast_float
make install JLEVEL=4
```

# Compile the port for QNX on Ubuntu host
```bash
# Create a workspace
mkdir -p ~/qnx_workspace && cd qnx_workspace
# Clone the repos
git clone https://github.com/xtang2010/build-files.git
git clone https://github.com/fastfloat/fast_float.git
git switch v8.2.2

# source qnxsdp-env.sh
source ~/qnx800/qnxsdp-env.sh

# Build libevent
cd ~/qnx_workspace/build-files/ports/fast_float
make install JLEVEL=4
```
