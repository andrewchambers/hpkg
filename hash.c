#include "h.h"
#include "sha256.h"
#include <errno.h>
#include <janet.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

typedef struct {
  enum {
    kind_sha256,
  } kind;
  union {
    Sha256ctx *sha256;
  } ctx;
} Hasher;

static void hasher_add(Hasher *h, char *b, size_t n) {
  switch (h->kind) {
  case kind_sha256:
    sha256_update(h->ctx.sha256, (uint8_t *)b, n);
    break;
  default:
    abort();
  }
}

static int hasher_add_file(Hasher *h, FILE *f) {
  char buf[65536];
  while (1) {
    int n = fread(buf, 1, sizeof(buf), f);
    if (n > 0) {
      hasher_add(h, buf, n);
    }
    if (n == 0)
      break;
  }
  return !ferror(f);
}

static void hasher_add_file_contents_at_path(Hasher *h, const char *path) {
  FILE *f = fopen(path, "rb");
  if (!f)
    janet_panicf("unable to open %s: %s", path, strerror(errno));
  int ok = hasher_add_file(h, f);
  fclose(f);
  if (!ok)
    janet_panicf("io error while hashing %s", path);
}

Janet sha256_file_hash(int argc, Janet *argv) {
  janet_fixarity(argc, 1);
  Sha256ctx ctx;
  sha256_init(&ctx);
  Hasher h;
  h.kind = kind_sha256;
  h.ctx.sha256 = &ctx;
  if (janet_checkabstract(argv[0], &janet_file_type)) {
    FILE *f = janet_unwrapfile(argv[0], NULL);
    if (!hasher_add_file(&h, f))
      janet_panicf("error hashing file");
  } else if (janet_checktype(argv[0], JANET_STRING)) {
    hasher_add_file_contents_at_path(
        &h, (const char *)janet_unwrap_string(argv[0]));
  } else {
    janet_panicf("file hash expects a file object or path, got %v", argv[0]);
  }
  uint8_t buf[32];
  uint8_t hexbuf[sizeof(buf) * 2];
  sha256_finish(&ctx, buf);
  base16_encode((char *)hexbuf, (char *)buf, sizeof(buf));
  return janet_stringv(hexbuf, sizeof(hexbuf));
}
