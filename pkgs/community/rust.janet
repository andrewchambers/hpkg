(use ../prelude)
(use ../base)
(use ./openssl)
(use ./zlib)
(use ./cmake)
(use ./ninja)
(use ./python3)

(defsrc rust-bootstrap-src
  :url
  "https://static.rust-lang.org/dist/rust-1.45.2-x86_64-unknown-linux-musl.tar.gz"
  :hash
  "sha256:1518bc5255c248a62a58562368e0a54f61fe02fd50f97f68882a65a62b100c17")

(def rust-bootstrap
  (hpkg/pkg
    :name "rust-bootstrap"
    :make-depends [gcc-rt-heavy base-dev rust-bootstrap-src]
    :depends [gcc-rt-heavy]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *
    sh install.sh \
          --disable-ldconfig \
          --prefix="" \
          --destdir="$out" \
          --components="rustc,cargo,rust-std-x86_64-unknown-linux-musl"
    ```))

(defsrc rust-src
  :url
  "https://static.rust-lang.org/dist/rustc-1.45.2-src.tar.gz"
  :hash
  "sha256:b7a3fc1e3ee367260ef945da867da0957f8983705f011ba2a73715375e50e308")

(def rust
  (hpkg/pkg
    :name "rust"
    :make-depends [gcc-rt-heavy base-dev openssl zlib cmake ninja python3 rust-bootstrap rust-src]
    :depends [openssl zlib]
    :build
    ```
    #! /bin/sh
    set -eux
    tar xf /src/*
    cd *

    export RUST_BACKTRACE=1
    cat <<EOF > config.toml
    [llvm]

    static-libstdcpp = true
    ninja = true

    [build]

    build = "x86_64-unknown-linux-musl"
    cargo = "/bin/cargo"
    rustc = "/bin/rustc"
    docs = false
    submodules = false
    extended = true
    vendor = true
    verbose = 2
    print-step-timings = true

    [install]

    prefix = "/"
    sysconfdir = "/etc"

    [rust]

    lld = false
    default-linker = "gcc"
    channel = "stable"
    verbose-tests = true
    codegen-backends = ["llvm"]

    [target.x86_64-unknown-linux-musl]

    cc = "gcc"
    cxx = "g++"
    ar = "ar"
    ranlib = "ranlib"
    linker = "gcc"
    crt-static = false
    musl-root = "/"

    [dist]

    EOF

    export HOME=/tmp
    export PYTHONHOME="/"
    DESTDIR="$out" python3 x.py install
    ```))
