(use ../prelude)
(use ../base)

(defsrc samurai-src
  :file-name
  "samurai-1.1.tar.gz"
  :url
  "https://github.com/michaelforney/samurai/archive/1.1.tar.gz"
  :hash
  "sha256:9f31e45e65c0b270c0dae431460c53bc0a254dc98385947e3ab507b7b986a162")

(def samurai
  (hpkg/pkg
    :name "samurai"
    :make-depends [base-dev gcc-rt-lite samurai-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    make -j$(nproc) install CC=gcc PREFIX="" DESTDIR="$out"
    ```))