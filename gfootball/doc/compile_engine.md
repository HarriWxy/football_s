# Compiling Google Research Football Engine #

This guide is intended to contain detailed information on building the environment
on different platforms and architectures. So far, it covers:
* [Windows](#windows),
* [macOS](#macos),
* [Linux](#linux).

Additionally, [Development mode](#development-mode) section explains how to install the game
in the development (aka, editable) mode.

## Windows
Install prerequisites:
- [Git](https://git-scm.com/download/win),
- [CMake](https://cmake.org/download/),
- [Visual Studio 2019 Community Edition](https://visualstudio.microsoft.com/downloads/) (make sure to
  select "Desktop development with C++" component),
- [Python 3](https://www.python.org/downloads/).

Finally, install [vcpkg](https://github.com/microsoft/vcpkg) by following a
  [Quick Start Guide](https://github.com/microsoft/vcpkg#quick-start-windows) or simply by creating a directory,
  e.g., `C:\dev`, opening Command Prompt and running the following commands:
```commandline
:: Navigate to the created directory
cd C:\dev
:: Clone vckpg
git clone https://github.com/microsoft/vcpkg.git
:: Run installation script
.\vcpkg\bootstrap-vcpkg.bat
```

If you have `vcpkg` already installed, consider updating it to the latest commit and running `.\bootstrap-vcpkg.bat`.

As for the C++ engine dependencies (`boost`, `SDL`, etc.), you don't have to install them manually, `vcpkg's`
[manifest mode](https://github.com/microsoft/vcpkg/blob/master/docs/users/manifests.md) will handle it.

Next, run the following lines in the command prompt to install Google Research Football environment:
```commandline
:: Clone the repository
git clone https://github.com/google-research/football.git
cd football
:: Set VCPKG_ROOT environment variable that points to vcpkg installation
set VCPKG_ROOT=C:\dev\vcpkg\

:: Create and activate virtual environment
python -m venv football-env
football-env\Scripts\activate.bat
:: For PowerShell users: football-env\Scripts\activate.ps1

:: Upgrade pip and install additional packages
python -m pip install --upgrade pip setuptools wheel
python -m pip install psutil

:: Run the installation. It installs vcpkg dependencies and compiles the engine
python -m pip install .
```


## macOS (both Intel processors and Apple Silicon)

### Install prerequisites
First, install [brew](https://brew.sh/). It should automatically download Command Line Tools.
Next, install the required packages:
```shell
brew install git python3 cmake sdl2 sdl2_image sdl2_ttf sdl2_gfx boost boost-python3

python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install psutil
```
Clone the repository and navigate to the directory:
```shell
git clone https://github.com/google-research/football.git
cd football
```

### Choosing Python distribution
It is recommended to use Python shipped with `brew` because `boost-python3` is compiled against the same version.
To check which Python 3 is used by default on your setup, execute `which python3`. If the output is `/usr/local/bin/python3`
or `/opt/homebrew/bin/python3`, you're good to go.  
If you see a different path, e.g. `/Library/Frameworks/Python.framework/Versions/3.9/bin/python3` or `...conda...`, 
create a virtual environment with `$(brew --prefix python3)/bin/python3 -m venv football-env`. If you have `conda`, 
you might need to deactivate base environment beforehand `conda deactivate`. 

It is possible to use `conda` to create a virtual environment, but make sure that you select the same version of Python 
that was used to build `boost-python3` (`3.9` as of February 2022).

### Create virtual environment and build the game
Use [virtual environment](https://docs.python.org/3/tutorial/venv.html) to avoid messing up with global dependencies:

```shell
python3 -m venv football-env
source football-env/bin/activate
```
If you decide to use `conda` environment, use the following commands instead:

```shell
conda create --name football-env python=3.9 -y
conda activate football-env
```

Upgrade `pip`, `setuptools`, `wheel` and install `psutil` inside the virtual environment:
```shell
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install psutil
```

Finally, build the game environment:

```shell
python3 -m pip install .
```


## Linux
Install required packages:

```shell
sudo apt-get install git cmake build-essential libgl1-mesa-dev libsdl2-dev \
libsdl2-image-dev libsdl2-ttf-dev libsdl2-gfx-dev libboost-all-dev \
libdirectfb-dev libst-dev mesa-utils xvfb x11vnc python3-pip

python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install psutil
```

Clone the repository and navigate to the directory:
```shell
git clone https://github.com/google-research/football.git
cd football
```

Use [virtual environment](https://docs.python.org/3/tutorial/venv.html) to avoid messing up with global dependencies:

```shell
python3 -m venv football-env
source football-env/bin/activate
# update pip and setuptools
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install psutil
```

Finally, build the game environment:

```shell
python3 -m pip install .
```

### Python 3.13 from uv

Ubuntu's `libboost-python-dev` is built for the distribution Python version.
When using a Python 3.13 interpreter managed by `uv`, build a matching
Boost.Python library and keep it in a separate prefix:

```shell
FOOTBALL_ROOT="$(pwd)"
GFOOTBALL_PYTHON="$FOOTBALL_ROOT/.venv/bin/python"
PYTHON_ROOT="$("$GFOOTBALL_PYTHON" -c 'import sys; print(sys.base_prefix)')"
BOOST_PREFIX="$FOOTBALL_ROOT/.cache/boost-python313"

mkdir -p "$FOOTBALL_ROOT/.cache"
curl -fL -o "$FOOTBALL_ROOT/.cache/boost_1_92_0.tar.gz" \
  https://archives.boost.io/release/1.92.0/source/boost_1_92_0.tar.gz
tar -C "$FOOTBALL_ROOT/.cache" -xf "$FOOTBALL_ROOT/.cache/boost_1_92_0.tar.gz"
cd "$FOOTBALL_ROOT/.cache/boost_1_92_0"

./bootstrap.sh --with-python="$GFOOTBALL_PYTHON" --with-python-root="$PYTHON_ROOT"
./b2 -j"$(nproc)" --layout=system --with-python --with-thread --with-system \
  --with-filesystem variant=release link=shared threading=multi \
  --stagedir="$BOOST_PREFIX" stage
mkdir -p "$BOOST_PREFIX/include"
cp -a boost "$BOOST_PREFIX/include/"
```

`stage` deliberately replaces `install`: Boost 1.92's `install` target can
fail while processing the unrelated header-only Histogram library. `stage`
builds the requested binary libraries without that target; the final `cp`
provides the headers expected by CMake.

Confirm that the generated library is version-specific:

```shell
find "$BOOST_PREFIX/lib" -maxdepth 1 -name 'libboost_python313.so*'
```

Then build/install Football with the same interpreter and Boost prefix:

```shell
cd "$FOOTBALL_ROOT"
GFOOTBALL_PYTHON="$GFOOTBALL_PYTHON" \
GFOOTBALL_BOOST_ROOT="$BOOST_PREFIX" \
  "$GFOOTBALL_PYTHON" -m pip install ./engines/gfootball
```

`GFOOTBALL_PYTHON` forces CMake to use the selected Python interpreter,
headers, and library. `GFOOTBALL_BOOST_ROOT` forces it to use the matching
Boost libraries and embeds their library directory as a build RPATH.

## Development mode

You can install Google Research Football
in the [development](https://packaging.python.org/guides/distributing-packages-using-setuptools/#id66)
(aka editable) mode by running:

```shell
python3 -m pip install -e .
```

In such case, Python source files can be edited in-place without reinstallation,
the changes will be reflected the next time an interpreter process is started.
