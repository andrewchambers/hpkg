(use ../prelude)
(use ../base)

(defsrc perl-src
  :url
  "https://www.cpan.org/src/5.0/perl-5.30.2.tar.gz"
  :hash
  "sha256:66db7df8a91979eb576fac91743644da878244cf8ee152f02cd6f5cd7a731689")

(def perl
  (hpkg/pkg
    :name "perl"
    :make-depends [base-dev perl-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    ./configure.gnu -Dcc=gcc
    make -j$(nproc) install-strip DESTDIR="$out"
    ```))