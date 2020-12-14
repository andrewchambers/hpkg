(use ../prelude)
(use ../base)
(use ./bash)

(defsrc bootstrap-go-src
  :file-name "go-bootstrap.tar.gz"
  :url "https://dl.google.com/go/go1.4-bootstrap-20171003.tar.gz"
  :hash "sha256:f4ff5b5eb3a3cae1c993723f3eab519c5bae18866b5e5f96fe1102f0cb5c3e52")

(defsrc go-src
  :url "https://golang.org/dl/go1.15.6.src.tar.gz"
  :hash "sha256:890bba73c5e2b19ffb1180e385ea225059eb008eb91b694875dd86ea48675817")

(def go
  (hpkg/pkg
    :name "go"
    :make-depends [base-dev bash gcc-rt-lite bootstrap-go-src go-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    export TMPDIR="/tmp"
    tar xf /src/go-bootstrap*
    cd *
    export GOROOT_BOOTSTRAP="$(pwd)"
    cd src
    bash ./make.bash
    cd "$out"
    mkdir bin libexec
    cd libexec
    tar xf /src/go1*
    mv * go-root
    cd go-root/src
    bash ./make.bash
    ln -s "$out/libexec/go-root/bin/go" "$out/bin/go"
    ln -s "$out/libexec/go-root/bin/gofmt" "$out/bin/gofmt"
    ```))