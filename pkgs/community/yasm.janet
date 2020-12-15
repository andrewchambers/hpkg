(use ../prelude)
(use ../base)

(defsrc yasm-src
  :url
  "http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz"
  :hash
  "sha256:3dce6601b495f5b3d45b59f7d2492a340ee7e84b5beca17e48f862502bd5603f")

(def yasm
  (hpkg/pkg
    :name "yasm"
    :make-depends [base-dev yasm-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix=""
    make -j$(nproc) install-strip DESTDIR="$out"
    ```))
