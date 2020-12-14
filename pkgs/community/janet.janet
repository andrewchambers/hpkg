(use ../prelude)
(use ../base)


(defsrc janet-src
  :url
  "https://github.com/janet-lang/janet/archive/v1.12.2.tar.gz"
  :hash
  "sha256:1cdbc4e944fb429a80bb415b657fc955579a4d7b1206fed9b32b9c60b20e477c"
  :file-name
  "janet.tar.gz")

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
    make -j$(nproc)
    make install DESTDIR="$out"
    ```))
