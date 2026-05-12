# libpcap port to QNX

This is to port [libpcap](https://www.tcpdump.org/) to QNX. libpcap is a portable application programming interface (API) for user-level network packet capture.

## Features

- Supports raw packet capture on QNX SDP 8.0+
- Supports both x86_64 and aarch64 architectures
- Supports shared library and static library builds
- Supports remote capture via rpcapd (optional)

## Prerequisites

- QNX SDP 8.0 or later
- Build environment with CMake support
- Source code cloned from libpcap repository

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

# Clone libpcap source
cd ~/qnx_workspace
git clone https://github.com/the-tcpdump-group/libpcap.git

# Build libpcap
make -C build-files/ports/libpcap -j4
```

### On Ubuntu host

```bash
# Clone the repos
mkdir -p ~/qnx_workspace && cd ~/qnx_workspace
git clone https://github.com/qnx-ports/build-files.git
git clone https://github.com/the-tcpdump-group/libpcap.git

# Source your SDP
source ~/qnx800/qnxsdp-env.sh

# Build libpcap
make -C build-files/ports/libpcap -j4
```

## Build output

The build will produce:
- `libpcap.so.X.X` - shared library
- `libpcap.a` - static library
- Headers in `include/pcap/`

The binaries will be installed to:
```
/usr/local/stage/libpcap/<platform>/libpcap/
```

## Installation

After building, the libraries and headers will be installed in the staging area. You can copy them to your QNX target:

```bash
# Copy libraries to target
scp build-files/ports/libpcap/ntox86_64-o/build_*/bin/libpcap.so.* qnxuser@$TARGET_HOST:/usr/local/lib/

# Copy headers to target  
scp -r build-files/ports/libpcap/ntox86_64-o/build_*/include/pcap qnxuser@$TARGET_HOST:/usr/local/include/
```

## Dependencies

- None (libpcap is a standalone library)

## Testing

To test your build on the target:

```bash
# Compile a simple test program
qcc -Vgcc_ntox86_64 -o test_libpcap test_libpcap.c -L/usr/local/lib -lpcap

# Run on target
./test_libpcap
```

## Patch notes

This port includes the following patches:
- QNX-specific atomic operations handling
- Zero-copy BPF disabled due to QNX compatibility issues
