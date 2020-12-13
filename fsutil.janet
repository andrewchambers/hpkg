(import ./build/_h)

(defn nuke-path
  [p]
  (when (os/stat p)
    (os/execute ["chmod" "-R" "+w" p] :xp)
    (os/execute ["rm" "-rf" p] :xp))
  nil)

(defn check-path-hash
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

(defn assert-path-hash
  [path expected]
  (match (check-path-hash path expected)
    :ok
    nil
    [:fail actual]
    (error
      (string/format "hash check failed!\npath: %s\nexpected: %v\ngot: %v" path expected actual))))