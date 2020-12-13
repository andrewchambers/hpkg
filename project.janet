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
  :cflags
  ["-Isha256/"
   "-Iblake3/"
   # TODO remove these...
   "-DBLAKE3_NO_SSE2"
   "-DBLAKE3_NO_SSE41"
   "-DBLAKE3_NO_AVX2"
   "-DBLAKE3_NO_AVX512"
   "-O3"]
  :source
  ["h.c"
   "hash.c"
   "util.c"
   "sha256/sha256.c"
   "blake3/blake3.c"
   "blake3/blake3_dispatch.c"
   "blake3/blake3_portable.c"
   # TODO enable these...
   #"blake3/blake3_sse2_x86-64_unix.S"
   #"blake3/blake3_sse41_x86-64_unix.S"
   #"blake3/blake3_avx2_x86-64_unix.S"
   #"blake3/blake3_avx512_x86-64_unix.S"
])
