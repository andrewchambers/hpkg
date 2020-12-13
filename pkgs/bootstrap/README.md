# Bootstrapping

Our package tree is self contained, but it can't start from nothing, it needs 
start from a binary seed. This directory lets you build your own binary seed
from alternate linux distributions.

Steps for bootstrapping:

- Build seed.tar.gz with seed.sh, this builds a statically linked gcc and busybox.
- Build a statically linked bootstrap.c, linked against libarchive.
- Host both files somewhere hpkg can download them, in your bootstrap building
  execute the bootstrap binary, and it will unpack the seed into $out.
