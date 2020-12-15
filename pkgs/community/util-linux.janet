(use ../prelude)
(use ../base)

(defsrc util-linux-src
  :url "https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.35/util-linux-2.35.1.tar.gz"
  :hash "sha256:37ac05d82c6410d89bc05d43cee101fefc8fe6cf6090b3ce7a1409a6f35db606")

(def util-linux
  (hpkg/pkg
    :name "util-linux"
    :make-depends [base-dev util-linux-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure --prefix="" \
      --disable-bash-completion \
      --disable-makeinstall-chown \
      --disable-makeinstall-setuid \
      --disable-nls
    make -j$(nproc) install-strip DESTDIR="$out"
    ```))
