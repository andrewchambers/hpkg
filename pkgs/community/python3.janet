(use ../prelude)
(use ../base)
(use ./libffi)
(use ./zlib)
(use ./openssl)

(defsrc python3-src
  :url
  "https://www.python.org/ftp/python/3.8.3/Python-3.8.3.tgz"
  :hash
  "sha256:6af6d4d2e010f9655518d0fc6738c7ff7069f10a4d2fbd55509e467f092a8b90")

(def python3
  (hpkg/pkg
    :name "python3"
    :make-depends [base-dev zlib libffi openssl python3-src]
    :depends [gcc-rt-lite zlib libffi openssl]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix="" --enable-optimizations
    make -j$(nproc) install DESTDIR="$out"
    ```))