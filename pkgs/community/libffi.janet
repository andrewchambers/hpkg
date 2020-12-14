(use ../prelude)
(use ../base)

(defsrc libffi-src
  :url
  "https://github.com/libffi/libffi/releases/download/v3.3/libffi-3.3.tar.gz"
  :hash
  "sha256:72fba7922703ddfa7a028d513ac15a85c8d54c8d67f55fa5a4802885dc652056")

(def libffi
  (hpkg/pkg
    :name "libffi"
    :make-depends [base-dev libffi-src]
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
