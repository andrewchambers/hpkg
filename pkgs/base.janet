(use ./prelude)

(def bootstrap
  (hpkg/pkg :name "bootstrap"
            :content [{:path "/bin/bootstrap"
                       :perms "r-xr-xr-x"
                       :url "https://github.com/andrewchambers/hpkgs-seeds/blob/master/bootstrap?raw=true"
                       :hash "sha256:7af191353cfe1569650d3f5503ddf1fd60166891995ce67deeb1e076a12c5821"}
                      {:path "seed.tar.gz"
                       :url "https://github.com/andrewchambers/hpkgs-seeds/blob/master/linux-x86_64-seed.tar.gz?raw=true"
                       :hash "sha256:e8e8c93b8662f06c3fa48acd266517356acb458962009ce39b5c8ca54eef7318"}]))

(def seed
  (hpkg/pkg :name "seed"
            :build "#! /bin/bootstrap"
            :make-depends [bootstrap]))

(def seed-bb
  (hpkg/pkg :name "seed-bb"
            :build
            ```
         #! /bin/sh
         set -eux
         mkdir "$out/bin"
         cp /bin/busybox "$out/bin/busybox" 
         for c in $("$out"/bin/busybox --list) ; do ln -s /bin/busybox "$out/bin/$c"  ; done
          
         ```
            :make-depends [seed]))

(def seed-gcc-rt
  (hpkg/pkg :name "seed-gcc-rt"
            :build
            ```
         #! /bin/sh
         set -eux
         mkdir "$out"/lib
         cp -vr /x86_64-linux-musl/lib/*.so* "$out/lib"
         ```
            :make-depends [seed]))

(defsrc make-src
  :url
  "https://ftp.gnu.org/gnu/make/make-4.2.tar.gz"
  :hash
  "sha256:e968ce3c57ad39a593a92339e23eb148af6296b9f40aa453a9a9202c99d34436")

(defsrc dash-src
  :url
  "http://gondor.apana.org.au/~herbert/dash/files/dash-0.5.10.2.tar.gz"
  :hash
  "sha256:3c663919dc5c66ec991da14c7cf7e0be8ad00f3db73986a987c118862b5f6071")

(defsrc coreutils-src
  :url
  "https://ftp.gnu.org/gnu/coreutils/coreutils-8.31.tar.xz"
  :hash
  "sha256:ff7a9c918edce6b4f4b2725e3f9b37b0c4d193531cac49a48b56c4d0d3a9e9fd")

(defsrc awk-src
  :url
  "https://ftp.gnu.org/gnu/gawk/gawk-5.0.1.tar.xz"
  :hash
  "sha256:8e4e86f04ed789648b66f757329743a0d6dfb5294c3b91b756a474f1ce05a794")

(defsrc diffutils-src
  :url
  "https://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz"
  :hash
  "sha256:b3a7a6221c3dc916085f0d205abf6b8e1ba443d4dd965118da364a1dc1cb3a26")

(defsrc findutils-src
  :url
  "https://ftp.gnu.org/pub/gnu/findutils/findutils-4.7.0.tar.xz"
  :hash
  "sha256:c5fefbdf9858f7e4feb86f036e1247a54c79fc2d8e4b7064d5aaa1f47dfa789a")

(defsrc patch-src
  :url
  "https://ftp.gnu.org/gnu/patch/patch-2.7.tar.gz"
  :hash
  "sha256:59c29f56faa0a924827e6a60c6accd6e2900eae5c6aaa922268c717f06a62048")

(defsrc sed-src
  :url
  "https://ftp.gnu.org/gnu/sed/sed-4.7.tar.xz"
  :hash
  "sha256:2885768cd0a29ff8d58a6280a270ff161f6a3deb5690b2be6c49f46d4c67bd6a")

(defsrc grep-src
  :url
  "https://ftp.gnu.org/gnu/grep/grep-3.3.tar.xz"
  :hash
  "sha256:b960541c499619efd6afe1fa795402e4733c8e11ebf9fafccc0bb4bccdc5b514")

(defsrc which-src
  :url
  "https://ftp.gnu.org/gnu/which/which-2.21.tar.gz"
  :hash
  "sha256:f4a245b94124b377d8b49646bf421f9155d36aa7614b6ebf83705d3ffc76eaad")

(defsrc tar-src
  :url
  "https://ftp.gnu.org/gnu/tar/tar-1.32.tar.gz"
  :hash
  "sha256:b59549594d91d84ee00c99cf2541a3330fed3a42c440503326dab767f2fbb96c")

(defsrc gzip-src
  :url
  "https://ftp.gnu.org/gnu/gzip/gzip-1.10.tar.gz"
  :hash
  "sha256:c91f74430bf7bc20402e1f657d0b252cb80aa66ba333a25704512af346633c68")

(defsrc bzip2-src
  :url
  "https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
  :hash
  "sha256:ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269")

(defsrc xz-src
  :url
  "https://tukaani.org/xz/xz-5.2.4.tar.gz"
  :hash
  "sha256:b512f3b726d3b37b6dc4c8570e137b9311e7552e8ccbab4d39d47ce5f4177145")

(defsrc pkgconf-src
  :url
  "https://distfiles.dereferenced.org/pkgconf/pkgconf-1.6.3.tar.xz"
  :hash
  "sha256:61f0b31b0d5ea0e862b454a80c170f57bad47879c0c42bd8de89200ff62ea210")

(def make-static
  (hpkg/pkg :name "make-static"
            :build
            ```
         #! /bin/sh
         set -eux
         tar xf /src/*
         cd *
         export CC="x86_64-linux-musl-gcc -static"
         ./configure --prefix=""
         ./build.sh
         ./make install-strip DESTDIR="$out"
         ```
            :make-depends [seed make-src]))

(def patch-static
  (hpkg/pkg :name "patch-static"
            :build
            ```
         #! /bin/sh
         set -eux
         tar xf /src/*
         cd *
         export CC="x86_64-linux-musl-gcc -static"
         ./configure --prefix=""
         make -j$(nproc) install-strip DESTDIR="$out"
         ```
            :make-depends [seed make-static patch-src]))

(def gcc-src
  (hpkg/pkg :name "gcc-src"
            :content [{:path "/src/mcm.tar.gz"
                       :url "https://github.com/richfelker/musl-cross-make/archive/v0.9.9.tar.gz"
                       :hash "sha256:ff3e2188626e4e55eddcefef4ee0aa5a8ffb490e3124850589bcaf4dd60f5f04"}

                      {:path "/src/gcc-9.2.0.tar.xz"
                       :url "https://ftp.gnu.org/pub/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.xz"
                       :hash "sha256:ea6ef08f121239da5695f76c9b33637a118dcf63e24164422231917fa61fb206"}

                      {:path "/src/binutils-2.33.1.tar.xz"
                       :url "https://ftp.gnu.org/pub/gnu/binutils/binutils-2.33.1.tar.xz"
                       :hash "sha256:ab66fc2d1c3ec0359b8e08843c9f33b63e8707efdff5e4cc5c200eae24722cbf"}

                      {:path "/src/gmp-6.1.2.tar.bz2"
                       :url "https://ftp.gnu.org/pub/gnu/gmp/gmp-6.1.2.tar.bz2"
                       :hash "sha256:5275bb04f4863a13516b2f39392ac5e272f5e1bb8057b18aec1c9b79d73d8fb2"}

                      {:path "/src/mpc-1.1.0.tar.gz"
                       :url "https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz"
                       :hash "sha256:6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"}

                      {:path "/src/mpfr-4.0.2.tar.bz2"
                       :url "https://ftp.gnu.org/pub/gnu/mpfr/mpfr-4.0.2.tar.bz2"
                       :hash "sha256:c05e3f02d09e0e9019384cdd58e0f19c64e6db1fd6f5ecf77b4b1c61ca253acc"}

                      {:path "/src/musl-1.2.0.tar.gz"
                       :url "https://www.musl-libc.org/releases/musl-1.2.0.tar.gz"
                       :hash "sha256:c6de7b191139142d3f9a7b5b702c9cae1b5ee6e7f57e582da9328629408fd4e8"}

                      {:path "/src/linux-4.19.90.tar.xz"
                       :url "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.90.tar.xz"
                       :hash "sha256:29d86c0a6daf169ec0b4b42a12f8d55dc894c52bd901f876f52a05906a5cf7fd"}

                      {:path "/src/config.sub"
                       :url "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=3d5db9ebe860"
                       :hash "sha256:75d5d255a2a273b6e651f82eecfabf6cbcd8eaeae70e86b417384c8f4a58d8d3"}]))

(def gcc
  (hpkg/pkg
    :name "gcc"
    :build
    ```
    #!/bin/sh
    set -eux
    tar xvf /src/mcm*
    cd *
    mkdir sources
    for f in /src/* ; do ln -s "$f" ./sources/$(basename "$f") ; done
    cat <<EOF > config.mak
    TARGET = x86_64-linux-musl
    NATIVE = yes
    LINUX_VER = 4.19.90
    OUTPUT = $out
    GCC_CONFIG += --enable-bootstrap --enable-default-pie --with-native-system-header-dir=/include
    GCC_CONFIG += --disable-libquadmath --disable-decimal-float --disable-libitm --disable-fixed-point
    COMMON_CONFIG += --enable-new-dtags --with-sysroot
    COMMON_CONFIG += CC="gcc"
    COMMON_CONFIG += CXX="g++"
    COMMON_CONFIG += CFLAGS="-O3 -pipe" CXXFLAGS="-O3 -pipe" LDFLAGS="-s"
    DL_CMD=false
    EOF
    make extract_all
    make -j $(nproc)
    make install
    cd "$out/bin"
    ln -s /lib/ld-musl-x86_64.so.1 ldd
    ```
    :make-depends [patch-static make-static seed seed-gcc-rt gcc-src]))

# XXX can we strip?
(def gcc-rt-lite
  (hpkg/pkg
    :name "gcc-rt-lite"
    :build
    ```
    #!/bin/sh
    set -eux
    mkdir "$out/lib/"
    cp -r /x86_64-linux-musl/lib/*.so* "$out/lib/"
    rm -f "$out"/lib/libstdc++* "$out"/lib/libgomp*
    ```
    :make-depends [seed gcc]))

(def gcc-rt-heavy
  (hpkg/pkg
    :name "gcc-rt-heavy"
    :build
    ```
    #!/bin/sh
    set -eux
    mkdir "$out/lib/"
    cp -r /x86_64-linux-musl/lib/*.so* "$out/lib/"
    ```
    :make-depends [seed gcc]))

(defmacro defbase
  [name &keys {:make-depends make-depends
               :depends depends
               :post-install post-install
               :configure configure}]
  (default configure `./configure --prefix=""`)

  ~(def ,name
     (hpkg/pkg :name ,(string name)
               :build
               (string
                 ```
              #! /bin/sh
              set -eux
              tar xf /src/*
              cd *

              ```
                 ,configure
            ```

              make -j$(nproc) install-strip DESTDIR="$out"
              
              ```
                 ,post-install)
               :make-depends ,make-depends
               :depends ,depends)))

(defbase make
  :make-depends [gcc gcc-rt-lite make-static seed-bb make-src]
  :depends [gcc-rt-lite])

(defbase make
  :make-depends [gcc gcc-rt-lite make-static seed-bb make-src]
  :depends [gcc-rt-lite])

(defbase coreutils
  :make-depends [gcc gcc-rt-lite make-static seed-bb coreutils-src]
  :depends [gcc-rt-lite]
  :configure `./configure --prefix="" --disable-nls`
  :post-install `mkdir -p "$out/usr/bin"; ln -s /bin/env "$out/usr/bin/env"`)

(defbase dash
  :make-depends [gcc gcc-rt-lite make seed-bb dash-src]
  :depends [gcc-rt-lite]
  :post-install `ln -s /bin/dash "$out/bin/sh"`)

(defbase awk
  :make-depends [gcc gcc-rt-lite make seed-bb awk-src]
  :configure `./configure --prefix="" --disable-nls`
  :depends [gcc-rt-lite])

(defbase diffutils
  :make-depends [gcc gcc-rt-lite make seed-bb diffutils-src]
  :depends [gcc-rt-lite])

(defbase findutils
  :make-depends [gcc gcc-rt-lite make seed-bb findutils-src]
  :depends [gcc-rt-lite])

(defbase patch
  :make-depends [gcc gcc-rt-lite make seed-bb patch-src]
  :depends [gcc-rt-lite]
  :post-install `rm "$out/lib/charset.alias"`)

(defbase sed
  :make-depends [gcc gcc-rt-lite make seed-bb sed-src]
  :depends [gcc-rt-lite])

(defbase grep
  :make-depends [gcc gcc-rt-lite make seed-bb grep-src]
  :depends [gcc-rt-lite])

(defbase gzip
  :make-depends [gcc gcc-rt-lite make seed-bb gzip-src]
  :depends [gcc-rt-lite])

(defbase which
  :make-depends [gcc gcc-rt-lite make seed-bb which-src]
  :depends [gcc-rt-lite])

(defbase tar
  :make-depends [gcc gcc-rt-lite make seed-bb tar-src]
  :configure `./configure --prefix="" --disable-nls`
  :depends [gcc-rt-lite])

(defbase xz
  :make-depends [gcc gcc-rt-lite make seed-bb xz-src]
  :depends [gcc-rt-lite])

(defbase pkgconf
  :make-depends [gcc gcc-rt-lite make seed-bb pkgconf-src]
  :depends [gcc-rt-lite]
  :post-install `ln -s /bin/pkgconf "$out/bin/pkg-config"`)

(def base
  (hpkg/pkg
    :name "base"
    # XXX It seems a builder should not be required.
    :build "#!/bin/dash"
    :make-depends [dash]
    :depends [gcc-rt-lite dash coreutils awk diffutils findutils patch sed grep gzip which tar xz]))

(def base-dev
  (hpkg/pkg
    :name "base"
    # XXX It seems a builder should not be required.
    :build "#!/bin/dash"
    :make-depends [base]
    :depends [make pkgconf gcc base]))
