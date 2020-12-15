(use ../prelude)
(use ../base)
(use ./perl)
(use ./autoconf)

(defsrc automake-src
  :url
  "https://ftp.gnu.org/gnu/automake/automake-1.16.tar.gz"
  :hash
  "sha256:80da43bb5665596ee389e6d8b64b4f122ea4b92a685b1dbd813cd1f0e0c2d83f")

(def automake
  (hpkg/pkg
    :name "automake"
    :make-depends [base-dev perl autoconf automake-src]
    :depends [gcc-rt-lite perl]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix=""
    make -j$(nproc) install-strip DESTDIR="$out"
    ```))
