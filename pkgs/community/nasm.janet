(use ../prelude)
(use ../base)
(use ./perl)

(defsrc nasm-src
  :url
  "https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.xz"
  :hash
  "sha256:e24ade3e928f7253aa8c14aa44726d1edf3f98643f87c9d72ec1df44b26be8f5")

(def nasm
  (hpkg/pkg
    :name "nasm"
    :make-depends [base-dev perl nasm-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix=""
    make -j$(nproc) install DESTDIR="$out"
    strip "$out/bin/"*
    ```))
