FOOTBALL_ROOT="$PWD"
GFOOTBALL_PYTHON="$FOOTBALL_ROOT/../../.venv/bin/python"
PYTHON_ROOT="$("$GFOOTBALL_PYTHON" -c 'import sys; print(sys.base_prefix)')"
BOOST_PREFIX="$FOOTBALL_ROOT/.cache/boost-python313"

echo "PYTHON_ROOT=$PYTHON_ROOT"

# mkdir -p "$FOOTBALL_ROOT/.cache"
# curl -fL -o "$FOOTBALL_ROOT/.cache/boost_1_92_0.tar.gz" \
#   https://archives.boost.io/release/1.92.0/source/boost_1_92_0.tar.gz
# tar -C "$FOOTBALL_ROOT/.cache" -xf "$FOOTBALL_ROOT/.cache/boost_1_92_0.tar.gz"

cd "$FOOTBALL_ROOT/.cache/boost_1_92_0"
./bootstrap.sh --with-python="$GFOOTBALL_PYTHON" --with-python-root="$PYTHON_ROOT"
./b2 -j"$(nproc)" --layout=system --with-python --with-thread --with-system \
  --with-filesystem variant=release link=shared threading=multi \
  --prefix="$BOOST_PREFIX" install