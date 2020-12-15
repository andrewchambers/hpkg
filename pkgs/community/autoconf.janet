(use ../prelude)
(use ../base)
(use ./m4)
(use ./perl)

(defsrc autoconf-src
  :url
  "https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz"
  :hash
  "sha256:64ebcec9f8ac5b2487125a86a7760d2591ac9e1d3dbd59489633f9de62a57684")

(def autoconf
  (hpkg/pkg
    :name "autoconf"
    :make-depends [base-dev m4 perl autoconf-src]
    :depends [gcc-rt-lite m4 perl]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix=""
    make -j$(nproc) install-strip DESTDIR="$out"
    ```))
