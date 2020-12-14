(use ../prelude)
(use ../base)
(use ./perl)

(defsrc libcap-src
  :url
  "https://kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.46.tar.xz"
  :hash
  "sha256:4ed3d11413fa6c9667e49f819808fbb581cd8864b839f87d7c2a02c70f21d8b4")

(def libcap
  (hpkg/pkg
    :name "libcap"
    :make-depends [base-dev perl libcap-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    make lib=lib prefix=/ RAISE_SETFCAP=no DESTDIR="$out" install
    ```))