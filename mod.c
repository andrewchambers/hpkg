#include "hpkg.h"

static const JanetReg cfuns[] = {
    {"pkg", make_pkg, NULL}, {"file-hash", file_hash, NULL}, {NULL, NULL, NULL}};

JANET_MODULE_ENTRY(JanetTable *env) {
  janet_register_abstract_type(&pkg_type);
  janet_cfuns(env, "h", cfuns);
}