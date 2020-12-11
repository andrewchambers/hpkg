(import path)
(import sqlite3)
(import flock)
(import shlex)
(import posix-spawn)
(import sh)
(import ./build/_h)

(defn pkg
  [&keys {:name name
          :build build
          :content content
          :make-depends make-depends
          :depends depends}]
  (default name "")
  (default make-depends [])
  (default depends [])
  (_h/pkg name build content make-depends depends))

(defn recursive-pkg-dependencies [pkgs]
  (def deps @{})
  (def ordered-deps @[])

  (defn recursive-pkg-dependencies
    [pkg]
    (unless (in deps pkg)
      (put deps pkg true)
      (array/push ordered-deps pkg)
      (each dep (pkg :depends)
        (recursive-pkg-dependencies dep))))

  (each pkg pkgs
    (recursive-pkg-dependencies pkg))

  ordered-deps)

(defn init-pkg-store
  [p]
  (defn ensure-dir-exists
    [d]
    (unless (os/stat d)
      (os/mkdir d)))

  (ensure-dir-exists p)
  (ensure-dir-exists (path/join p "pkg"))
  (ensure-dir-exists (path/join p "lock"))

  (with [db (sqlite3/open (path/join p "hermes.db"))]
    (sqlite3/eval db "begin immediate;")
    (when (empty? (sqlite3/eval db "select name from sqlite_master where type='table' and name='Meta'"))
      (sqlite3/eval db "create table Roots(LinkPath text primary key);")
      (sqlite3/eval db "create table Pkgs(Hash text primary key, Name text);")
      (sqlite3/eval db "create table Meta(Key text primary key, Value text);")
      (sqlite3/eval db "insert into Meta(Key, Value) Values('StoreVersion', 1);")
      (sqlite3/eval db "commit;")))
  :ok)

(var- *store-is-open* false)
(var- *store-path* nil)
(var- *store-db* nil)

(defn open-pkg-store
  [pkg-store-path]
  (def pkg-store-path (path/abspath pkg-store-path))
  (def db-path (path/join pkg-store-path "hermes.db"))
  (unless (os/stat db-path)
    (errorf "no package database at %p" db-path))
  (def db (sqlite3/open db-path))
  (set *store-is-open* true)
  (set *store-path* pkg-store-path)
  (set *store-db* db)
  :ok)

(defn pkg-path
  [pkg]
  (def name (pkg :name))
  (def sep (if (empty? name) "" "-"))
  (path/join *store-path* "pkg" (string name sep (pkg :hash))))

(defn has-pkg?
  [pkg]
  (not (empty? (sqlite3/eval *store-db* "select 1 from Pkgs where Hash=:hash" {:hash (pkg :hash)}))))

(defn- acquire-gc-lock
  [block mode]
  (flock/acquire (path/join *store-path* "lock/gc.lock") block mode))

(defn- acquire-build-lock
  [pkg block mode]
  (flock/acquire (path/join *store-path* "lock" (string (pkg :hash) ".lock")) block mode))

(defn- nuke-path
  [p]
  (when (os/stat p)
    (os/execute ["chmod" "-R" "+w" p] :xp)
    (os/execute ["rm" "-rf" p] :xp))
  nil)

(defn- check-path-hash
  [path expected]

  (defn- hash
    [algo path]
    (string algo ":"
            (match algo
              "sha256"
              (_h/sha256-file-hash path)
              _
              (error (string "unsupported hash algorithm - " algo)))))

  (def algo
    (if-let [idx (string/find ":" expected)]
      (string/slice expected 0 idx)
      (error (string/format "expected ALGO:VALUE, got %v" expected))))
  (def actual
    (hash algo path))
  (if (= expected actual)
    :ok
    [:fail actual]))

(defn- assert-path-hash
  [path expected]
  (match (check-path-hash path expected)
    :ok
    nil
    [:fail actual]
    (error
      (string/format "hash check failed!\npath: %s\nexpected: %v\ngot: %v" path expected actual))))

(var build-pkg* nil)

(defn- build-pkg-from-content-spec
  [pkg]
  (def full-pkg-path (pkg-path pkg))

  (def build-lock (acquire-build-lock pkg :noblock :exclusive))
  (unless build-lock
    (errorf "package %s is already being built" (pkg-path pkg)))

  (defer (:close build-lock)
    (nuke-path full-pkg-path)
    (os/mkdir full-pkg-path)
    (os/mkdir (path/join full-pkg-path "fs"))

    (each content-spec (pkg :content)
      (def content-path
        (path/join full-pkg-path "fs" (path/normalize (content-spec :path))))
      (eprintf "downloading %s to %s" (content-spec :url) content-path)
      (os/execute ["mkdir" "-p" (path/dirname content-path)] :xp)
      (os/execute ["curl" "-L" "-o" content-path (content-spec :url)] :xp)
      (assert-path-hash content-path (content-spec :hash))
      (when-let [perms (content-spec :perms)]
        (os/chmod content-path perms))))
  nil)

(var- pkgfs-bin nil)
(defn- find-pkgfs-bin
  []

  # XXX this does not check exec bit,
  # This should maybe be in the stdlib.
  # https://github.com/janet-lang/janet/issues/528

  (defn look-path [exe]
    (def PATH (os/getenv "PATH"))
    (when (or (nil? PATH) (empty? PATH))
      (error "PATH not set"))
    (var r nil)
    (each p (string/split ":" (os/getenv "PATH" ""))
      (def full-p (path/join p exe))
      (when (os/stat full-p)
        (set r full-p)
        (break)))
    (unless r
      (errorf "%v not found in PATH" exe))
    r)

  (if pkgfs-bin
    pkgfs-bin
    (set pkgfs-bin (look-path "pkgfs"))))

(defn- build-pkg-from-build-script
  [pkg]

  (each dep (pkg :depends)
    (build-pkg* dep))
  (each dep (pkg :make-depends)
    (build-pkg* dep))

  (def full-pkg-path (pkg-path pkg))

  (def build-lock (acquire-build-lock pkg :noblock :exclusive))
  (unless build-lock
    (errorf "package %s is already being built" (pkg-path pkg)))

  (defer (:close build-lock)

    (eprintf "preparing build env for %s ..." (pkg-path pkg))

    (nuke-path full-pkg-path)

    (os/mkdir full-pkg-path)

    (def fs-dir (path/join full-pkg-path "fs"))
    (os/mkdir fs-dir)

    (def mnt-dir (path/join full-pkg-path "mnt"))
    (os/mkdir mnt-dir)

    (def chroot (path/join full-pkg-path "build-chroot"))
    (def chroot-tmp (path/join chroot "/tmp"))
    (def chroot-bin (path/join chroot "/bin"))
    (def chroot-etc (path/join chroot "/etc"))
    (def chroot-var (path/join chroot "/var"))
    (def chroot-out (path/join chroot "/out"))
    (def chroot-proc (path/join chroot "/proc"))
    (def chroot-dev (path/join chroot "/dev"))
    (def chroot-build (path/join chroot "/build"))
    (def chroot-paths [chroot chroot-bin chroot-etc chroot-var
                       chroot-out chroot-build chroot-tmp chroot-proc chroot-dev])

    (each p chroot-paths
      (os/mkdir p))

    (def build-script (path/join chroot "builder"))
    (spit build-script (pkg :build))
    (os/chmod build-script 8r755)

    (def union-paths
      (array/concat @[chroot]
                    (map |(path/join (pkg-path $) "fs")
                         (recursive-pkg-dependencies (pkg :make-depends)))))
    (with [fs-proc (posix-spawn/spawn [(find-pkgfs-bin)
                                       "-f"
                                       "-oauto_unmount,kernel_cache"
                                       ;union-paths
                                       mnt-dir])]

      # wait for fs to come up, can we improve from busy waiting?
      (let [builder-path (path/join mnt-dir "builder")]
        (while (not (os/stat builder-path))
          (os/sleep 0.1)
          (when (fs-proc :exit-code)
            (error "fuse filesystem exited during setup"))))

      (os/execute
        ["nsjail"
         "-Mo"
         "-q"
         "-t" "0"
         "-B" (string fs-dir ":/out")
         "-B" "/dev"
         "-m" "none:/build:tmpfs:size=10000000000"
         "-m" "none:/tmp:tmpfs:size=10000000000"
         "-E" "out=/out"
         "-E" "PATH=/bin:/usr/bin:/usr/local/bin"
         "-D" "/build"
         "--chroot" mnt-dir
         "--rlimit_as" "max"
         "--rlimit_cpu" "max"
         "--rlimit_fsize" "max"
         "--rlimit_nofile" "max"
         "--rlimit_nproc" "max"
         "--rlimit_stack" "max"
         "--" "/builder"]
        :xp)

      (when (fs-proc :exit-code)
        (error "fuse filesystem exited during build")))

    (nuke-path mnt-dir)
    (nuke-path chroot))
  nil)

(varfn build-pkg*
  [pkg]
  (def full-pkg-path (pkg-path pkg))
  (unless (has-pkg? pkg)
    (if (pkg :content)
      (build-pkg-from-content-spec pkg)
      (build-pkg-from-build-script pkg))
    (spit
      (path/join full-pkg-path "pkg.jdn")
      (string/format "%j" {:depends (map |($ :hash) (pkg :depends))}))

    (sqlite3/eval *store-db* "insert into Pkgs(Hash, Name) Values(:hash, :name);"
                  {:hash (pkg :hash) :name (pkg :name)}))
  full-pkg-path)

(defn build-pkg
  [pkg]
  (unless *store-is-open*
    (error "package store is not open, use 'open-pkg-store'"))

  (def gc-lock (acquire-gc-lock :noblock :shared))

  (unless gc-lock
    (error "garbage collection in progress"))

  (defer (:close gc-lock)
    (build-pkg* pkg)))

(defn venv
  [out-path pkgs &keys {:binds binds}]
  (def out-path (path/abspath out-path))

  (default binds ["bin" "lib" "usr"])

  (unless *store-is-open*
    (error "package store is not open, use 'open-pkg-store'"))

  (def gc-lock (acquire-gc-lock :noblock :shared))

  (unless gc-lock
    (error "garbage collection in progress"))

  (defer (:close gc-lock)
    (each pkg pkgs
      (build-pkg* pkg))

    (def all-pkgs (recursive-pkg-dependencies pkgs))
    (def run-path (path/join out-path "run"))

    (when (os/stat out-path)
      (unless (os/stat run-path)
        (errorf "%v already exists and is not an existing venv" out-path)))

    (os/mkdir out-path)
    (def all-fs-paths (map |(path/join (pkg-path $) "fs") all-pkgs))
    (eprintf "copying files to venv...")
    (os/execute ["rsync" "--delete" "-a" ;all-fs-paths out-path] :xp)

    (spit run-path
          (string
            ```
            #! /bin/sh
            set -e
            unset venv_binds
            for b in $(ls /)
            do

            ```
            ;(map |(string "  if test \"$b\" = " (shlex/quote $) " ; then continue ; fi\n") binds)
            ```
              venv_binds+=(--bind "/$b" "/$b")
            done

            exec bwrap \

            ```
            ;(map |(string "  --dev-bind-try " (shlex/quote (path/join out-path "fs" $)) " " (shlex/quote $) " \\\n") binds)
            ```
              "${venv_binds[@]}" \
              --chdir "$PWD" \
              -- "$@"
            ```))
    (os/execute ["chmod" "+x" run-path] :xp))
  :ok)
