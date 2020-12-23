(use ../prelude)
(use ../base)


(defsrc janet-src
  :url
  "https://github.com/janet-lang/janet/archive/v1.13.1.tar.gz"
  :hash
  "sha256:7d369b72a1fc649f7e5c254e2b746eb36885970504f6d9d3441507ca2d716644"
  :file-name
  "janet-1.13.1.tar.gz")

(def janet
  (hpkg/pkg
    :name "janet"
    :make-depends [base-dev janet-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    export PREFIX=""
    make CC=gcc -j$(nproc)
    make install DESTDIR="$out"
    ```))
