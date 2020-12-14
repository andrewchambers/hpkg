(use ../prelude)
(use ../base)
(use ./openssl)

(defsrc cmake-src
  :url
  "https://github.com/Kitware/CMake/releases/download/v3.17.2/cmake-3.17.2.tar.gz"
  :hash
  "sha256:fc77324c4f820a09052a7785549b8035ff8d3461ded5bbd80d252ae7d1cd3aa5")

(def cmake
  (hpkg/pkg
    :name "cmake"
    :make-depends [gcc-rt-heavy base-dev openssl cmake-src]
    :depends [gcc-rt-heavy openssl]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix=""
    make -j$(nproc) install DESTDIR="$out"
    ```))