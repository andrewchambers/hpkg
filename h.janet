(import path)
(import sqlite3)
(import flock)
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
  (os/execute ["rm" "-rf" p] :xp)
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

(var build-pkg*)

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
      (os/execute ["mkdir" "-p" (path/dirname content-path)] :xp)
      (os/execute ["curl" "-L" "-o" content-path (content-spec :url)] :xp)
      (assert-path-hash content-path (content-spec :hash))
      (when-let [perms (content-spec :perms)]
        (os/chmod content-path perms))))
  nil)

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
    (nuke-path full-pkg-path)
    (os/mkdir full-pkg-path)
    (os/mkdir (path/join full-pkg-path "fs"))
    (os/mkdir (path/join full-pkg-path "build-chroot"))

    (nuke-path full-pkg-path))
  nil)

(varfn build-pkg*
  [pkg]
  (unless (has-pkg? pkg)
    (if (pkg :content)
      (build-pkg-from-content-spec pkg)
      (build-pkg-from-build-script pkg))
    (spit
      (path/join full-pkg-path "pkg.jdn")
      (string/format "%j" {:depends (map |($ :hash) (pkg :depends))}))

    (sqlite3/eval *store-db* "insert into Pkgs(Hash, Name) Values(:hash, :name);"
                  {:hash (pkg :hash) :name (pkg :name)})))

(defn build-pkg
  [pkg]
  (unless *store-is-open*
    (error "package store is not open, use 'open-pkg-store'"))

  (def gc-lock (acquire-gc-lock :noblock :shared))

  (unless gc-lock
    (error "garbage collection in progress"))

  (def full-pkg-path (pkg-path pkg))

  (defer (:close gc-lock)
    (build-pkg* pkg))

  full-pkg-path)
