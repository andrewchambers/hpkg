#!/bin/sh
set -eux
version=0.3.7
test -e ./upgrade-blake3.sh
rm -rf BLAKE3-$version.tar.gz BLAKE3-$version/
curl -L https://github.com/BLAKE3-team/BLAKE3/archive/0.3.7.tar.gz -o BLAKE3-$version.tar.gz
tar xf BLAKE3-$version.tar.gz
rm -f *.c *.h *.S
cp BLAKE3-$version/c/*.c ./
cp BLAKE3-$version/c/*.h ./
cp BLAKE3-$version/c/*.S ./
rm -rf BLAKE3-$version.tar.gz BLAKE3-$version/
git add *.c *.h *.S