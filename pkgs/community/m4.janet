(use ../prelude)
(use ../base)

(defsrc m4-src
  :url
  "https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz"
  :hash
  "sha256:f2c1e86ca0a404ff281631bdc8377638992744b175afb806e25871a24a934e07")

(def m4
  (hpkg/pkg
    :name "m4"
    :make-depends [base-dev m4-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix="" --disable-nls
    make -j$(nproc) install-strip DESTDIR="$out"
    rm "$out/lib/charset.alias"
    rmdir "$out/lib"
    ```))
