---
title: How to install googletest library?
created: 2018-05-18T00:00:00Z
description: The following guide provides instructions on how to compile and add googletest (gtest) to a C++ project. See how to compile and install googletest and googlemock. Use pkg-config to obtain compiler flags. Then set up the libraries to build your cmake project.
keywords: googletest, c++, compilation, unit testing, gtest, googletest installation, googlemock, library, pkg-config, linux, cmake, mocking, tests, how to install gtest, gtest build, build googletest, how to build googletest, gtest installation
slug: how-to-set-up-googletest-library-from-source
---

Setting up googletest (or gtest, C++ unit testing library) can be tricky. When starting a new project, integrating googletest can be problematic, despite having no such issues with other libraries.

The following guide provides instructions on how to compile and add googletest to a C++ project. It uses `pkg-config` to obtain compiler flags and works with build systems such as `cmake`.

It was tested on Ubuntu but might work on other systems as well.

## Download and compile googletest

Download the latest release from [https://github.com/google/googletest/releases](https://github.com/google/googletest/releases)

```bash
wget https://github.com/google/googletest/archive/release-1.8.0.tar.gz
```

and extract it:

```bash
tar xzf release-1.8.0.tar.gz
cd googletest-release-1.8.0
```

After that, we can compile it:

```bash
mkdir build && cd build
cmake ..
make -j
```

Now, copy the headers to a directory where compilers can find them:

```bash
sudo cp -r ../googletest/include /usr/local/include
```

Then, copy static libraries:

```bash
sudo cp -r ./googlemock/gtest/libgtest*.a /usr/local/lib/
```

Additionally, you can also add googlemock library (C++ framework for mocking objects):

```bash
sudo cp -r ./googlemock/libgmock*.a /usr/local/lib/
```

## Find googletest with `pkg-config`

After compiling and installing library files, try to find the library with `pkg-config`:

```bash
pkg-config --libs --cflags gtest
```

If you get a message about gtest not being found ("Package gtest was not found in the pkg-config search path") then it means `pkg-config` cannot find gtest's `.pc` file which provides the necessary configuration.

Run the following command to see the list of directories read by pkg-config:

```bash
pkg-config --variable pc_path pkg-config
```

Choose one of them, e.g. `/usr/lib/pkgconfig`, and inside that directory create a file named `gtest.pc` which should like similar to this:

```bash
prefix=/usr/local
exec_prefix=${prefix}
libdir=${prefix}/lib
includedir=${prefix}/include

Name: gtest
Description: gtest
Version: 1.8.0
Libs: -L${libdir} -lgtest -lpthread
Cflags: -I${includedir}
```

Having done that, the following command:

```bash
pkg-config  --libs --cflags gtest
```

should produce valid output, i.e. similar to

```bash
-I/usr/local/include -L/usr/local/lib -lgtest -lpthread
```

## Integrating googletest with cmake

If you use cmake to build your program, you can use `pkg-config` to find correct compilation flags.

First, in order to add support for `pkg-config` in cmake, add the following in `CMakeLists.txt`:

```cmake
find_package(PkgConfig)
```

Then, find gtest with `pkg-config`:

```cmake
pkg_check_modules(GTEST "gtest" REQUIRED)
```

You can verify that it's available by printing `GTEST_FOUND` variable

```cmake
message(STATUS "gtest found: " ${GTEST_FOUND})
```

and running `cmake .` on your project.

After you confirm cmake can find the library, just add a definition for your test executable, e.g.

```cmake
add_executable(test_1
  tests/test_1.cpp
)
```

and then link gtest with it:

```cmake
target_link_libraries(test_1 ${GTEST_LIBRARIES})
```

Running build command e.g. `cmake . && make` should now successfully build the executable.

That concludes googletest installation. See the next section if you need to add googlemock (C++ mocking library).

## Integrating googlemock with a C++ project

First, ensure you have copied `libgmock*.a` libraries to `/usr/local/lib`, i.e. by executing:
 
```bash
sudo cp -r ./googlemock/libgmock*.a /usr/local/lib/
```

Create `gmock.pc` configuration file in `/usr/lib/pkgconfig` so that `pkg-config` can resolve compiler flags:

```bash
prefix=/usr/local
exec_prefix=${prefix}
libdir=${prefix}/lib
includedir=${prefix}/include

Name: gmock
Description: gmock
Version: 1.8.0
Libs: -L${libdir} -lgmock -lpthread
Cflags: -I${includedir}
```

Then, find gmock in `CMakeLists.txt`:

```cmake
pkg_check_modules(GMOCK "gmock" REQUIRED)
```

Finally, link your tests with googlemock by adding `${GMOCK_LIBRARIES}` variable:

```cmake
target_link_libraries(test_readdir ${GTEST_LIBRARIES} ${GMOCK_LIBRARIES})
```

After all those steps, tests using googletest/googlemock should compile correctly by executing standard commands (`cmake . && make`)!
