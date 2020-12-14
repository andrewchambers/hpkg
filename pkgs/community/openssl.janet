(use ../prelude)
(use ../base)
(use ./perl)

(defsrc openssl-src
  :url
  "https://www.openssl.org/source/openssl-1.1.1g.tar.gz"
  :hash
  "sha256:ddb04774f1e32f0c49751e21b67216ac87852ceb056b75209af2443400636d46")

(def openssl
  (hpkg/pkg
    :name "openssl"
    :make-depends [perl base-dev openssl-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./config --prefix="/"
    make -j$(nproc)
    make install DESTDIR="$out"
    ```))