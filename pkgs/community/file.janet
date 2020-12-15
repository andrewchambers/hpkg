(use ../prelude)
(use ../base)

(defsrc file-src
  :url
  "ftp://ftp.astron.com/pub/file/file-5.38.tar.gz"
  :hash
  "sha256:593c2ffc2ab349c5aea0f55fedfe4d681737b6b62376a9b3ad1e77b2cc19fa34")

(def file
  (hpkg/pkg
    :name "file"
    :make-depends [base-dev file-src]
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
