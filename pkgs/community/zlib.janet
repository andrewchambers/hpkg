(use ../prelude)
(use ../base)

(defsrc zlib-src
  :url
  "https://www.zlib.net/zlib-1.2.11.tar.gz"
  :hash
  "sha256:c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1")

(def zlib
  (hpkg/pkg
    :name "zlib"
    :make-depends [base-dev zlib-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix=""
    make -j$(nproc)
    make install DESTDIR="$out"
    ```))
