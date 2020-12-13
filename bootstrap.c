#include <archive.h>
#include <archive_entry.h>
#include <stdio.h>
#include <stdlib.h>

static int copy_data(struct archive *ar, struct archive *aw) {
  int r;
  const void *buff;
  size_t size;
  la_int64_t offset;

  for (;;) {
    r = archive_read_data_block(ar, &buff, &size, &offset);
    if (r == ARCHIVE_EOF)
      return (ARCHIVE_OK);
    if (r < ARCHIVE_OK)
      return (r);
    r = archive_write_data_block(aw, buff, size, offset);
    if (r != ARCHIVE_OK) {
      return (r);
    }
  }
}

int main() {
  char *out;
  struct archive *a;
  struct archive *ext;
  struct archive_entry *entry;
  int flags, r;

  out = getenv("out");
  if (!out) {
    fprintf(stderr, "unable to read $out env var\n");
    exit(1);
  }

  if (chdir(out) != 0) {
    perror("unable to chdir to $out");
    exit(1);
  }

  flags = ARCHIVE_EXTRACT_TIME;
  flags |= ARCHIVE_EXTRACT_PERM;
  flags |= ARCHIVE_EXTRACT_ACL;
  flags |= ARCHIVE_EXTRACT_FFLAGS;

  a = archive_read_new();
  archive_read_support_format_tar(a);
  archive_read_support_filter_gzip(a);
  ext = archive_write_disk_new();
  archive_write_disk_set_options(ext, flags);
  archive_write_disk_set_standard_lookup(ext);
  if ((r = archive_read_open_filename(a, "/seed.tar.gz", 10240)))
    exit(1);
  for (;;) {
    r = archive_read_next_header(a, &entry);
    if (r == ARCHIVE_EOF)
      break;
    if (r != ARCHIVE_OK) {
      fprintf(stderr, "%s\n", archive_error_string(a));
      exit(1);
    }

    r = archive_write_header(ext, entry);
    if (r != ARCHIVE_OK) {
      fprintf(stderr, "%s\n", archive_error_string(ext));
      exit(1);
    } else if (archive_entry_size(entry) > 0) {
      r = copy_data(a, ext);
      if (r != ARCHIVE_OK) {
        fprintf(stderr, "%s\n", archive_error_string(ext));
        exit(1);
      }
    }
    r = archive_write_finish_entry(ext);
    if (r != ARCHIVE_OK) {
      fprintf(stderr, "%s\n", archive_error_string(ext));
      exit(1);
    }
  }
  archive_read_close(a);
  archive_read_free(a);
  archive_write_close(ext);
  archive_write_free(ext);

  return 0;
}