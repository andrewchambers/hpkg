#include <janet.h>

typedef struct Pkg {
  Janet name;         // string
  Janet build;        // nil string
  Janet make_depends; // [Pkg]
  Janet depends;      // [Pkg]
  Janet content;      // [{:path :url :hash}] content struct.

  // Computed values
  Janet hash;
} Pkg;

extern const JanetAbstractType pkg_type;

/* hash.c */
Janet file_hash(int argc, Janet *argv);

/* util.c */
void base16_encode(char *outbuf, char *inbuf, size_t in_length);