#include <errno.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "blake3.h"
#include "hpkg.h"

static void validate_pkg(Pkg *pkg) {

  if (!janet_checktype(pkg->name, JANET_STRING))
    janet_panicf("name must be a string, got %v", pkg->name);

  JanetString name = janet_unwrap_string(pkg->name);
  size_t name_len = janet_string_length(name);
  if (name_len > 64)
    janet_panicf("name %p is too long, must be less than 64 chars", pkg->name);

  for (size_t i = 0; i < name_len; i++) {
    if (name[i] == '/')
      janet_panicf("name %p contains path separator.", pkg->name);
  }

  if (!janet_checktypes(pkg->hash, JANET_TFLAG_NIL | JANET_TFLAG_STRING))
    janet_panicf("hash must be a string or nil, got %p", pkg->hash);

  if (janet_type(pkg->build) == JANET_NIL &&
      janet_type(pkg->content) == JANET_NIL)
    janet_panicf("one of build or content must be non nil, (both nil)");

  if (janet_type(pkg->build) != JANET_NIL &&
      janet_type(pkg->content) != JANET_NIL)
    janet_panicf("one of build or content must be non nil, (both non nil)");

  if (!janet_checktypes(pkg->build, JANET_TFLAG_NIL | JANET_TFLAG_STRING))
    janet_panicf("builder must be a string or nil, got %v", pkg->build);

  if (!janet_checktypes(pkg->content, JANET_TFLAG_NIL | JANET_TFLAG_TUPLE))
    janet_panicf("content must be a tuple or nil, got %p", pkg->content);

  if (janet_checktype(pkg->content, JANET_TUPLE)) {
    const Janet *content = janet_unwrap_tuple(pkg->content);
    size_t content_len = janet_tuple_length(content);
    for (size_t i = 0; i < content_len; i++) {
      Janet c = content[i];
      if (!janet_checktype(c, JANET_STRUCT))
        janet_panicf("content[%d] must be a struct, got %p", i, content[i]);

      const JanetKV *ckv = janet_unwrap_struct(c);

      if (janet_struct_length(ckv) < 3)
        janet_panicf("content[%d] should have path, url and hash, got %p", i,
                     content[i]);

      Janet path = janet_struct_get(ckv, janet_ckeywordv("path"));
      Janet url = janet_struct_get(ckv, janet_ckeywordv("url"));
      Janet hash = janet_struct_get(ckv, janet_ckeywordv("hash"));
      Janet perms = janet_struct_get(ckv, janet_ckeywordv("perms"));

      if (!janet_checktype(path, JANET_STRING))
        janet_panicf("content[%d] path should be a string, got %p", i, path);

      if (!janet_checktype(url, JANET_STRING))
        janet_panicf("content[%d] url should be a string, got %p", i, url);

      if (!janet_checktype(url, JANET_STRING))
        janet_panicf("content[%d] hash should be a string, got %p", i, hash);

      if (!janet_checktypes(perms, JANET_TFLAG_NIL | JANET_TFLAG_STRING))
        janet_panicf("content[%d] perms should be nil or a string, got %p", i,
                     perms);
    }
  }

#define CHECK_PKG_TUPLE(NAME, V)                                               \
  do {                                                                         \
    if (janet_checktype(V, JANET_TUPLE)) {                                     \
      const Janet *vs = janet_unwrap_tuple(V);                                 \
      size_t n_vs = janet_tuple_length(vs);                                    \
      for (size_t i = 0; i < n_vs; i++) {                                      \
        if (!janet_checkabstract(vs[i], &pkg_type)) {                          \
          janet_panicf(NAME "[%d] must be a package, got %p", i, vs[i]);       \
        }                                                                      \
      }                                                                        \
    } else {                                                                   \
      janet_panicf(NAME " must be a tuple, got %p", V);                        \
    }                                                                          \
  } while (0);

  CHECK_PKG_TUPLE("make-depends", pkg->make_depends);
  CHECK_PKG_TUPLE("depends", pkg->depends);
#undef CHECK_PKG_TUPLE
}

static void hash_opt_string(blake3_hasher *hash_ctx, Janet v) {
  switch (janet_type(v)) {
  case JANET_NIL: {
    uint8_t t = 0;
    blake3_hasher_update(hash_ctx, &t, 1);
    break;
  }
  case JANET_STRING: {
    JanetString s = janet_unwrap_string(v);
    uint8_t buf[5];
    uint32_t n = (uint32_t)janet_string_length(s);
    buf[0] = 1;
    buf[1] = (n & 0xff) >> 0;
    buf[2] = (n & 0xff00) >> 8;
    buf[3] = (n & 0xff0000) >> 16;
    buf[4] = (n & 0xff000000) >> 24;
    blake3_hasher_update(hash_ctx, buf, sizeof(buf));
    blake3_hasher_update(hash_ctx, (uint8_t *)s, n);
    break;
  }
  default:
    abort();
  }
}

static void hash_pkg_tuple(blake3_hasher *hash_ctx, Janet v) {
  const Janet *tup = janet_unwrap_tuple(v);
  uint32_t n = (uint32_t)janet_tuple_length(tup);
  // hash tuple marker and size
  uint8_t buf[5];
  buf[0] = 2;
  buf[1] = (n & 0xff) >> 0;
  buf[2] = (n & 0xff00) >> 8;
  buf[3] = (n & 0xff0000) >> 16;
  buf[4] = (n & 0xff000000) >> 24;
  blake3_hasher_update(hash_ctx, buf, sizeof(buf));
  for (uint32_t i = 0; i < n; i++) {
    Pkg *p = janet_unwrap_abstract(tup[i]);
    hash_opt_string(hash_ctx, p->name);
    hash_opt_string(hash_ctx, p->hash);
  }
}

static void hash_pkg_content(blake3_hasher *hash_ctx, Janet v) {
  if (janet_checktype(v, JANET_TUPLE)) {
    const Janet *tup = janet_unwrap_tuple(v);
    uint32_t n = (uint32_t)janet_tuple_length(tup);
    // hash tuple marker and size
    uint8_t buf[5];
    buf[0] = 3;
    buf[1] = (n & 0xff) >> 0;
    buf[2] = (n & 0xff00) >> 8;
    buf[3] = (n & 0xff0000) >> 16;
    buf[4] = (n & 0xff000000) >> 24;
    blake3_hasher_update(hash_ctx, buf, sizeof(buf));
    for (uint32_t i = 0; i < n; i++) {
      const JanetKV *c = janet_unwrap_struct(tup[i]);
      // The urls of source code have no affect on the package hash.
      Janet path = janet_struct_get(c, janet_ckeywordv("path"));
      Janet hash = janet_struct_get(c, janet_ckeywordv("hash"));
      Janet perms = janet_struct_get(c, janet_ckeywordv("perms"));
      hash_opt_string(hash_ctx, path);
      hash_opt_string(hash_ctx, hash);
      hash_opt_string(hash_ctx, perms);
    }
  } else {
    uint8_t t = 0;
    blake3_hasher_update(hash_ctx, &t, 1);
  }
}

static Janet compute_pkg_hash(Pkg *pkg) {
  Janet hash;
  blake3_hasher hash_ctx;
  uint8_t hash_bytes[BLAKE3_OUT_LEN];
  uint8_t hash_hex_bytes[sizeof(hash_bytes) * 2];
  blake3_hasher_init(&hash_ctx);
  hash_opt_string(&hash_ctx, pkg->name);
  hash_opt_string(&hash_ctx, pkg->build);
  hash_pkg_content(&hash_ctx, pkg->content);
  hash_pkg_tuple(&hash_ctx, pkg->make_depends);
  hash_pkg_tuple(&hash_ctx, pkg->depends);
  blake3_hasher_finalize(&hash_ctx, hash_bytes, BLAKE3_OUT_LEN);
  base16_encode((char *)hash_hex_bytes, (char *)hash_bytes, sizeof(hash_bytes));
  hash = janet_stringv(hash_hex_bytes, sizeof(hash_hex_bytes));
  pkg->hash = hash;
  return janet_wrap_nil();
}

Janet make_pkg(int argc, Janet *argv) {
  janet_fixarity(argc, 5);

  Pkg *pkg = janet_abstract(&pkg_type, sizeof(Pkg));
  pkg->name = argv[0];
  pkg->build = argv[1];
  pkg->content = argv[2];
  pkg->make_depends = argv[3];
  pkg->depends = argv[4];
  pkg->hash = janet_wrap_nil();

  validate_pkg(pkg);
  compute_pkg_hash(pkg);

  return janet_wrap_abstract(pkg);
}

static int pkg_get(void *ptr, Janet key, Janet *out) {
  Pkg *pkg = ptr;
  if (janet_keyeq(key, "hash")) {
    *out = pkg->hash;
    return 1;
  } else if (janet_keyeq(key, "build")) {
    *out = pkg->build;
    return 1;
  } else if (janet_keyeq(key, "content")) {
    *out = pkg->content;
    return 1;
  } else if (janet_keyeq(key, "name")) {
    *out = pkg->name;
    return 1;
  } else if (janet_keyeq(key, "make-depends")) {
    *out = pkg->make_depends;
    return 1;
  } else if (janet_keyeq(key, "depends")) {
    *out = pkg->depends;
    return 1;
  } else {
    return 0;
  }
}

static int pkg_gcmark(void *p, size_t s) {
  (void)s;
  Pkg *pkg = p;
  janet_mark(pkg->name);
  janet_mark(pkg->build);
  janet_mark(pkg->content);
  janet_mark(pkg->make_depends);
  janet_mark(pkg->depends);
  janet_mark(pkg->hash);
  return 0;
}

static void pkg_marshal(void *p, JanetMarshalContext *ctx) {
  Pkg *pkg = p;
  janet_marshal_abstract(ctx, p);
  janet_marshal_janet(ctx, pkg->name);
  janet_marshal_janet(ctx, pkg->build);
  janet_marshal_janet(ctx, pkg->content);
  janet_marshal_janet(ctx, pkg->make_depends);
  janet_marshal_janet(ctx, pkg->depends);
}

static void *pkg_unmarshal(JanetMarshalContext *ctx) {
  Pkg *pkg = janet_unmarshal_abstract(ctx, sizeof(Pkg));
  pkg->name = janet_unmarshal_janet(ctx);
  pkg->build = janet_unmarshal_janet(ctx);
  pkg->content = janet_unmarshal_janet(ctx);
  pkg->make_depends = janet_unmarshal_janet(ctx);
  pkg->depends = janet_unmarshal_janet(ctx);
  pkg->hash = janet_wrap_nil();
  validate_pkg(pkg);
  compute_pkg_hash(pkg);
  return pkg;
}

const JanetAbstractType pkg_type = {
    "hpkg/pkg",    NULL, pkg_gcmark, pkg_get, NULL, pkg_marshal,
    pkg_unmarshal, NULL, NULL,       NULL,    NULL, NULL,
};
