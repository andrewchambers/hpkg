(use ../prelude)
(use ../base)

(defsrc bash-src
  :url "https://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz"
  :hash "sha256:b4a80f2ac66170b2913efbfb9f2594f1f76c7b1afd11f799e22035d63077fb4d")

(def bash
  (hpkg/pkg
    :name "bash"
    :make-depends [base-dev bash-src gcc-rt-lite]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --without-bash-malloc --prefix=""
    make -j$(nproc) install-strip DESTDIR="$out"
    ```))