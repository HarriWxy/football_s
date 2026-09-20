#!/bin/bash
# Copyright 2019 Google LLC
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

LIB_EXTENSION="so"

if [[ "$OSTYPE" == "darwin"* ]] ; then
    LIB_EXTENSION="dylib"
fi

# The C++ module must be built against the same interpreter that will import it.
# GFOOTBALL_PYTHON is preferred so callers do not need to modify PATH.  Keep
# PYTHON as a backwards-compatible fallback for existing build environments.
PYTHON="${GFOOTBALL_PYTHON:-${PYTHON:-python3}}"
PYTHON_ROOT="$("$PYTHON" -c 'import sys; print(sys.base_prefix)')"

# A distribution-provided Boost.Python is usually built for the distribution's
# default Python minor version.  A custom prefix lets callers supply, for
# example, libboost_python313.so built against a uv-managed Python 3.13.
BOOST_ROOT="${GFOOTBALL_BOOST_ROOT:-${BOOST_ROOT:-}}"
CMAKE_ARGS=(
    "-DPython_EXECUTABLE=$PYTHON"
    "-DPython_ROOT_DIR=$PYTHON_ROOT"
    "-DPython_FIND_STRATEGY=LOCATION"
)
if [[ -n "$BOOST_ROOT" ]]; then
    CMAKE_ARGS+=(
        "-DBoost_ROOT=$BOOST_ROOT"
        "-DBOOST_ROOT=$BOOST_ROOT"
        "-DCMAKE_PREFIX_PATH=$BOOST_ROOT"
        "-DCMAKE_BUILD_RPATH=$BOOST_ROOT/lib"
        "-DCMAKE_INSTALL_RPATH=$BOOST_ROOT/lib"
    )
fi

# Take into account # of cores and available RAM for deciding on compilation parallelism.
# TODO: Try importing psutil and if failed fall back to 1 thread
PARALLELISM=$("$PYTHON" -c 'import psutil; import multiprocessing as mp; print(int(max(1,min((psutil.virtual_memory().available/1000000000-1)/0.5, mp.cpu_count()))))')

# Delete pre-existing version of CMakeCache.txt to make 'python3 -m pip install' work.
rm -f third_party/gfootball_engine/CMakeCache.txt
pushd third_party/gfootball_engine
cmake . "${CMAKE_ARGS[@]}"
make -j "$PARALLELISM"
ln -sf "libgame.$LIB_EXTENSION" _gameplayfootball.so
popd
