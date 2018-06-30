---
title: How to set up googletest library from source?
created: 2018-05-18T00:00:00Z
description: The following guide provides instructions on how to compile and add googletest to a C++ project. It will use pkg-config to obtain compiler flags and can be used with a build system such as cmake.
keywords: googletest, c++, compilation, unit testing, library, pkg-config, linux, cmake, mocking, tests
---

I've noticed that setting up googletest (C++ unit testing library) can be tricky. When starting a new project, I had problems integrating googletest despite having no such problems with other libraries.

The following guide provides instructions on how to compile and add googletest to a C++ project. It will use `pkg-config` to obtain compiler flags and can be used with a build system such as cmake.

It is intended to work on Ubuntu but might work on other systems.

## Download and compile googletest

Download latest release from [https://github.com/google/googletest/releases](https://github.com/google/googletest/releases)

```
wget https://github.com/google/googletest/archive/release-1.8.0.tar.gz
```

and extract it

```
tar xzf release-1.8.0.tar.gz
cd googletest-release-1.8.0
```

After than, we can compile it:

```
mkdir build && cd build
cmake ..
make -j
```

Now, copy the headers to a directory where compilers can find them:

```
sudo cp -r ../googletest/include /usr/local/include
```

Then, copy static libraries:

```
sudo cp -r ./googlemock/gtest/libgtest*.a /usr/local/lib/
```

Additionally, you can also add googlemock library (mocking framework):

```
sudo cp -r ./googlemock/libgmock*.a /usr/local/lib/
```

## Find googletest with `pkg-config`

After compiling and installing library files, try to find the library with `pkg-config`:

```
pkg-config --libs --cflags gtest
```

If you get a message about gtest not being found ("Package gtest was not found in the pkg-config search path") then it essentially means `pkg-config` cannot find gtest's `.pc` file which provides configuration.

It can be added in any of the directories listed by

```
pkg-config --variable pc_path pkg-config
```

e.g. `/usr/lib/pkgconfig`

Create a file named `gtest.pc` which should like similar to this:

```
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

After that, verify that

```
pkg-config  --libs --cflags gtest
```

produces valid output, i.e. similar to

```
-I/usr/local/include -L/usr/local/lib -lgtest -lpthread
```

## Integrating googletest with cmake

If you use cmake to build your program, you can use `pkg-config` to find correct compilation flags.

First, in order to add support for `pkg-config` in cmake add the following in `CMakeLists.txt`:

```
find_package(PkgConfig)
```

Then, find gtest with `pkg-config`:

```
pkg_check_modules(GTEST "gtest" REQUIRED)
```

You can verify that it's available by printing `GTEST_FOUND` variable

```
message(STATUS "gtest found: " ${GTEST_FOUND})
```

and running `cmake .` on your project.

After you confirm cmake can find the library, just add a definition for your test executable, e.g.

```
add_executable(test_1
  tests/test_1.cpp
)
```

and then link gtest with it:

```
target_link_libraries(test_1 ${GTEST_LIBRARIES})
```

Running build command e.g. `cmake . && make` should now successfully build the executable.

That concludes googletest setup. See the next section if you need to add googlemock (C++ mocking library).

## Integrating googlemock with a C++ project

First, ensure you have copied `libgmock*.a` libraries to `/usr/local/lib` (see above).

Create `gmock.pc` configuration file in `/usr/lib/pkgconfig` so that `pkg-config` can resolve compiler flags:

```
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

```
pkg_check_modules(GMOCK "gmock" REQUIRED)
```

Finally, link your tests with googlemock by adding `${GMOCK_LIBRARIES}` variable:

```
target_link_libraries(test_readdir ${GTEST_LIBRARIES} ${GMOCK_LIBRARIES})
```

After all those steps, tests using googletest/googlemock should compile correctly by executing standard commands (`cmake . && make`)!
