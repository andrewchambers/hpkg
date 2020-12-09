(declare-project
  :name "h"
  :author "Andrew Chambers"
  :url "https://github.com/andrewchambers/h"
  :repo "git+https://github.com/andrewchambers/h.git"
  :dependencies ["https://github.com/janet-lang/sqlite3.git"
                 "https://github.com/janet-lang/argparse.git"
                 "https://github.com/janet-lang/path.git"
                 "https://github.com/andrewchambers/janet-flock.git"])

(declare-native
  :name "_h"
  :source ["util.c" "hash.c" "sha256.c" "h.c"])
