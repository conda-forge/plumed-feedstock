#!/bin/bash
set -ex

if [[ "${mpi}" != "nompi" ]]; then
  # make the MPI wrappers call the conda compilers
  export OMPI_CC="$CC" OMPI_CXX="$CXX"
  export MPICH_CC="$CC" MPICH_CXX="$CXX"
  mpi_bin="$PREFIX/bin"
  if [[ "${build_platform}" != "${target_platform}" && "${mpi}" == "openmpi" ]]; then
    # use the build-platform Open MPI wrappers but point them at the target prefix
    export OPAL_PREFIX="$PREFIX"
    mpi_bin="$BUILD_PREFIX/bin"
  fi
  export CC="$mpi_bin/mpicc" CXX="$mpi_bin/mpicxx"
fi

# STATIC_LIBS is a PLUMED specific option used when linking the plumed executable,
# which does not get LDFLAGS. Conda does not use LD_LIBRARY_PATH and the MPICH wrappers
# add no rpath, so the location of the dependent libraries must be given explicitly.
export STATIC_LIBS="-Wl,-rpath,$PREFIX/lib"
if [[ $(uname) == "Linux" ]]; then
  export STATIC_LIBS="-Wl,-rpath-link,$PREFIX/lib $STATIC_LIBS"
  # -lrt is required to link clock_gettime
  export LIBS="-lrt $LIBS"
fi

# we also store path so that software linking libplumedWrapper.a knows where libplumedKernel can be found.
export CPPFLAGS="-D__PLUMED_DEFAULT_KERNEL=$PREFIX/lib/libplumedKernel$SHLIB_EXT $CPPFLAGS"

# enable optimization
export CXXFLAGS="${CXXFLAGS//-O2/-O3}"

# libraries are explicitly listed here due to --disable-libsearch
export LIBS="-lfftw3 -lgsl -lgslcblas -llapack -lblas -lz $LIBS"

# python is disabled since it should be provided as a separate package
# --disable-libsearch forces to link only explicitely requested libraries
# --disable-static-patch avoid tests that are only required for static patches
# --disable-static-archive makes package smaller
./configure --prefix=$PREFIX --disable-python --disable-libsearch --disable-static-patch --disable-static-archive

if [[ "${mpi}" != "nompi" ]]; then
  # fail early if configure silently disabled MPI
  grep -q -- "-D__PLUMED_HAS_MPI" Makefile.conf || { echo "ERROR: MPI not enabled"; exit 1; }
fi

make -j${CPU_COUNT}
make install
