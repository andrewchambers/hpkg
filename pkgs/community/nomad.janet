(use ../prelude)
(use ../base)
(use ./go)

(defsrc nomad-src
  :file-name
  "nomad.tar.gz"
  :url
  "https://github.com/hashicorp/nomad/archive/v0.11.3.tar.gz"
  :hash
  "sha256:4ac797fd87a9e24a99e45a5dae91dd1064ab90a9da180ee2d0914a6ded4d3272")

(def nomad
  (hpkg/pkg
    :make-depends [go base-dev nomad-src]
    :depends [gcc-rt-lite]
    :build
    ```
    #! /bin/sh
    set -eux
    mkdir "$out/bin"
    export CGO_ENABLED=1
    export GOPATH=`pwd`
    export GOCACHE=`pwd`/cache
    tar xf /src/*
    mv * nomad
    mkdir -p src/github.com/hashicorp/
    mv nomad src/github.com/hashicorp/
    cd src/github.com/hashicorp/nomad
    go build \
      -trimpath \
      -ldflags "-s -w" \
      -tags "ui release nonvidia" \
      -o "$out/bin/nomad"
    ```))
