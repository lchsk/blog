---
title: How to use git submodules and CMake to install C++ libraries?
created: 2020-02-16T00:00:00Z
description: Install a C++ header-only library with git submodules and CMake.
keywords: git, git submodules, C++, c++, c, cpp, libraries, CMake, c++ libraries, header-only libraries
---

Installing C and C++ libraries is not easy as there isn't a widely accepted package management solution similar to what exists in languages such as Python, JavaScript etc.

With git submodules you can embed another repository inside your own. In that way, you can track your dependencies and update them similarly to like you would an ordinary git repository.

This example shows how to install a [C++ TOML parser](https://github.com/ToruNiina/toml11) as a dependency using git submodules and CMake.

First, create a directory for libraries inside the root of your project:

```
mkdir lib
```

Then, add the submodule inside the `lib` directory:

```
git submodule add https://github.com/ToruNiina/toml11 lib/toml11
```

At that point, git should clone that repository and put it in `lib/toml11`.

Now, we need to tell CMake where to find the library files.

Inside the `CMakeLists.txt` file define a variable, `EXTERNAL_LIB_HEADERS`, that lists external dependencies.

```cmake
set(EXTERNAL_LIB_HEADERS lib/toml11)
```

Now, add `EXTERNAL_LIB_HEADERS` to the list of directories where C++ compiler should be looking for header files.

```cmake
target_include_directories(
  executable_name PRIVATE
  ${EXTERNAL_LIB_HEADERS}
)
```

At that point, it should be ready to use. You can test it by including the header of the library and compiling your program.

```cpp
#include <toml.hpp>
```

As a side note I should add that having a lot of quickly evolving dependencies defined in such a way might be difficult to control. However, for relatively simple use cases, this is a straightforward and quick solution.
