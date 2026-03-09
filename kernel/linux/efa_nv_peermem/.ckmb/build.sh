#!/bin/bash -e

SRCDIR="$(pwd)"
BUILDDIR="${SRCDIR}/build"

mkdir -p "$BUILDDIR"

if hash cmake3 2>/dev/null; then
    # CentOS users are encouraged to install cmake3 from EPEL
    CMAKE=cmake3
else
    CMAKE=cmake
fi

cd "$BUILDDIR"

$CMAKE -DKERNEL_VER=${CKMB_KERNEL_FULL_VERSION} ${EXTRA_CMAKE_FLAGS:-} ..
make

# CKMB: Copy the built module to the source directory
cp ${BUILDDIR}/src/efa_nv_peermem.ko $SRCDIR/efa_nv_peermem.ko
