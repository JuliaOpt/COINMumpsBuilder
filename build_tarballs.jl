# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "COINMumpsBuilder"
version = v"1.6.0"

# Collection of sources required to build COINMumpsBuilder
sources = [
    "https://github.com/coin-or-tools/ThirdParty-Mumps/archive/releases/1.6.0.tar.gz" =>
    "3f2bb7d13333e85a29cd2dadc78a38bbf469bc3920c4c0933a90b7d8b8dc798a",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ThirdParty-Mumps-releases-1.6.0/
./get.Mumps
update_configure_scripts
# temporary fix
for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done
mkdir build
cd build/
## STATIC BUILD START
if [ $target = "x86_64-apple-darwin14" ]; then
  export AR=/opt/x86_64-apple-darwin14/bin/llvm-ar
fi
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
--with-blas-lib="-L$prefix/lib -lcoinblas"
## STATIC BUILD END

## DYNAMIC BUILD START
#../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --disable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
#--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
#--with-blas-lib="-L$prefix/lib -lcoinblas"
## DYNAMIC BUILD END

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)
# To fix gcc4 bug in Windows
push!(platforms, Windows(:i686,compiler_abi=CompilerABI(:gcc6)))
push!(platforms, Windows(:x86_64,compiler_abi=CompilerABI(:gcc6)))

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libcoinmumps", :libcoinmumps)
]

# Dependencies that must be installed before this package can be built
dependencies = [
        "https://github.com/JuliaOpt/COINBLASBuilder/releases/download/v1.4.6-1/build_COINBLASBuilder.v1.4.6.jl",
        "https://github.com/JuliaOpt/COINMetisBuilder/releases/download/v1.3.5-1/build_COINMetisBuilder.v1.3.5.jl"
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
