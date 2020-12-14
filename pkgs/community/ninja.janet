(use ../prelude)
(use ../base)
(use ./cmake)

(defsrc ninja-src
  :file-name
  "ninja-1.10.0.tar.gz"
  :url
  "https://github.com/ninja-build/ninja/archive/v1.10.0.tar.gz"
  :hash
  "sha256:3810318b08489435f8efc19c05525e80a993af5a55baa0dfeae0465a9d45f99f")

(def ninja
  (hpkg/pkg
    :name "ninja"
    :make-depends [gcc-rt-heavy cmake base-dev ninja-src]
    :depends [gcc-rt-heavy]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    cmake -Bbuild-cmake -H.
    cmake --build build-cmake --parallel $(nproc)
    mkdir -p "$out/bin"
    install -s build-cmake/ninja "$out/bin/ninja"
    ```))