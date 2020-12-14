(import hpkg :export true)
(import ./lib/path :export true)

(defmacro local-file
  [fpath]
  (unless (string/has-prefix? "./" fpath)
    (errorf "local-file macro requires the path be a string starting with './', got %v" fpath))
  (string "file://" (path/join (path/dirname (path/abspath (dyn :current-file))) fpath)))

(defmacro defsrc
  [name &keys {:url url :hash hash :file-name file-name}]
  
  (unless (or (nil? url) (string? url))
    (errorf ":url must be nil or string constant, got %p" url))
  (when (and (nil? url) (nil? file-name))
    (error ":url or :file-name is required"))

  (def url
    (when url
      (if (string/has-prefix? "./" url)
        (string "file://" (path/join (path/dirname (path/abspath (dyn :current-file))) url))
        url)))

  (def src-path 
    (string "/src/" (or file-name (last (string/split "/" url)))))

  ~(def ,name (,hpkg/pkg
                 :name ,(string name)
                 :content
                 [{:url ,url
                   :hash ,hash
                   :path ,src-path }])))

