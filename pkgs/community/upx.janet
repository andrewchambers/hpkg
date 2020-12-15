(use ../prelude)
(use ../base)
(use ./perl)
(use ./file)
(use ./zlib)

(defsrc ucl-src
  :url
  "http://www.oberhumer.com/opensource/ucl/download/ucl-1.03.tar.gz"
  :hash
  "sha256:b865299ffd45d73412293369c9754b07637680e5c826915f097577cd27350348")

(defsrc upx-src
  :url
  "https://github.com/upx/upx/releases/download/v3.96/upx-3.96-src.tar.xz"
  :hash
  "sha256:47774df5c958f2868ef550fb258b97c73272cb1f44fe776b798e393465993714")

# XXX: possibly an alternative to setting CPPFLAGS is:
# https://git.alpinelinux.org/aports/tree/community/ucl/0001-Static-assert.patch
# https://bugs.archlinux.org/task/49287
(def ucl
  (hpkg/pkg
    :name "ucl"
    :make-depends [base-dev file ucl-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    export CPPFLAGS="-std=c89 -fPIC"
    ./configure --prefix="" --enable-shared --enable-static
    make -j$(nproc) install DESTDIR="$out"
    ```))

(def upx
  (hpkg/pkg
    :name "upx"
    :make-depends [base-dev perl zlib ucl upx-src]
    :depends [gcc-rt-heavy zlib ucl]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/upx-*
    cd *
    export CXX="g++ -L/lib"
    make -j$(nproc) all \
      CHECK_WHITESPACE=/bin/true
    mkdir "$out/bin"
    cp src/upx.out "$out/bin/upx"
    ```))
