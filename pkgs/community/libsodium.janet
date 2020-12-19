(use ../prelude)
(use ../base)

(defsrc libsodium-src
  :url
  "https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz"
  :hash
  "sha256:6f504490b342a4f8a4c4a02fc9b866cbef8622d5df4e5452b46be121e46636c1")

(def libsodium
  (hpkg/pkg
    :name "libsodium"
    :make-depends [base-dev libsodium-src]
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
