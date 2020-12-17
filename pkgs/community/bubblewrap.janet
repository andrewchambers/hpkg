(use ../prelude)
(use ../base)
(use ./libcap)

(defsrc bubblewrap-src
  :url
  "https://github.com/containers/bubblewrap/releases/download/v0.4.1/bubblewrap-0.4.1.tar.xz"
  :hash
  "sha256:b9c69b9b1c61a608f34325c8e1a495229bacf6e4a07cbb0c80cf7a814d7ccc03")

# XXX why is the -I and -L needed, it should be handled by gcc...
(def bubblewrap
  (hpkg/pkg
    :name "bubblewrap"
    :make-depends [base-dev libcap bubblewrap-src]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    export CFLAGS="-O2 --static"
    ./configure --prefix=""
    make install-strip -j$(nproc) DESTDIR="$out"
    ```))
