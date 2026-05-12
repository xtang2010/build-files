# tcpdump port to QNX

This is to port [tcpdump](https://www.tcpdump.org/) to QNX. tcpdump is a powerful command-line packet analyzer that captures network traffic.

## Features

- Full packet capture and analysis on QNX SDP 8.0+
- Supports both x86_64 and aarch64 architectures
- Depends on libpcap for packet capture
- Compatible with tcpdump filter syntax

## Prerequisites

- QNX SDP 8.0 or later
- Build environment with CMake support
- libpcap must be built and installed first
- Source code cloned from tcpdump repository

## How to build

### Using Docker container

```bash
# Create a workspace
mkdir -p ~/qnx_workspace && cd ~/qnx_workspace
git clone https://github.com/qnx-ports/build-files.git

# Build the Docker image and create a container
cd build-files/docker
./docker-build-qnx-image.sh
./docker-create-container.sh

# Now you are in the Docker container

# Source your SDP
source ~/qnx800/qnxsdp-env.sh

# Clone libpcap and tcpdump source
cd ~/qnx_workspace
git clone https://github.com/the-tcpdump-group/libpcap.git
git clone https://github.com/the-tcpdump-group/tcpdump.git

# Build libpcap first
make -C build-files/ports/libpcap -j4

# Build tcpdump
make -C build-files/ports/tcpdump -j4
```

### On Ubuntu host

```bash
# Clone the repos
mkdir -p ~/qnx_workspace && cd ~/qnx_workspace
git clone https://github.com/qnx-ports/build-files.git
git clone https://github.com/the-tcpdump-group/libpcap.git
git clone https://github.com/the-tcpdump-group/tcpdump.git

# Source your SDP
source ~/qnx800/qnxsdp-env.sh

# Build libpcap first
make -C build-files/ports/libpcap -j4

# Build tcpdump
make -C build-files/ports/tcpdump -j4
```

## Build output

The build will produce the `tcpdump` executable in the build directory.

The binary will be installed to:
```
/usr/local/stage/tcpdump/<platform>/bin/
```

## Installation

After building, you can copy the binary to your QNX target:

```bash
# Copy tcpdump to target
scp build-files/ports/tcpdump/ntox86_64-o/build_*/bin/tcpdump qnxuser@$TARGET_HOST:/usr/local/bin/

# Also copy libpcap if not already installed
scp build-files/ports/libpcap/ntox86_64-o/build_*/bin/libpcap.so.* qnxuser@$TARGET_HOST:/usr/local/lib/
```

## Dependencies

- libpcap - Must be built and installed first

## Testing

After copying to target:

```bash
# Make sure LD_LIBRARY_PATH includes libpcap
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Run tcpdump
tcpdump -h
```

## Known issues

- Zero-copy BPF is not supported on QNX due to atomic.h incompatibility

## Patch notes

This port includes the following patches:
- QNX libsocket linking for networking functions
