(use ../prelude)
(use ../base)
(use ./perl)
(use ./nasm)
(use ./upx)
(use ./util-linux)

(defsrc syslinux-src
  :url
  "https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.xz"
  :hash
  "sha256:26d3986d2bea109d5dc0e4f8c4822a459276cf021125e8c9f23c3cca5d8c850e")

(def syslinux
  (hpkg/pkg
    :name "syslinux"
    :make-depends [base-dev perl upx nasm util-linux syslinux-src]
    :depends [gcc-rt-lite perl]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    patch -p1 <<EOF
    --- a/extlinux/main.c
    +++ b/extlinux/main.c
    @@ -41,6 +41,7 @@
     #include <sys/types.h>
     #include <sys/mount.h>
     #include <sys/vfs.h>
    +#include <sys/sysmacros.h>
     
     #include "linuxioctl.h"
    EOF

    export EXTRA_CFLAGS="-fno-PIE"
    make -j$(nproc) INSTALLROOT="$out" install
    ```))
