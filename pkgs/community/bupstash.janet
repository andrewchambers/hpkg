(use ../prelude)
(use ../base)
(use ./rust)
(use ./libsodium)

(defsrc bupstash-src
  :url
  "https://github.com/andrewchambers/bupstash/releases/download/v0.6.0/bupstash-v0.6.0-src+deps.tar.gz"
  :hash
  "sha256:4fb027f4d08df22758394cc61593624d8243b958af2ba7d75484179abe3a43f6")

(def bupstash
  (hpkg/pkg
    :name "bupstash"
    :make-depends [base-dev bupstash-src rust libsodium]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    export CC=gcc
    cargo build --offline --release
    mkdir "$out"/bin
    strip target/release/bupstash
    cp target/release/bupstash "$out"/bin
    ```))