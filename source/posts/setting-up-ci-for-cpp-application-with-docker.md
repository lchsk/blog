---
title: Setting up CI for a C++ application with Docker
created: 2018-12-16T00:00:00Z
description: How to set up continuous integration for a C++ application with Docker and open source CI service?
keywords: C++, cpp, docker, continuous integration, ci, travis, travis ci, gtk, sanchosql, sancho
slug: setting-up-ci-for-cpp-application-with-docker
---

Having an automated way to build an application and run tests is a convenient way to learn about failures as quickly as possible. It's as important for businesses as it is for smaller open-source projects.

## Why use Docker on CI?

There are a few reasons why it's worth to use Docker in a continuous integration environment. Keeping the build process isolated from the rest of the system is an important one. Having control of the operating system and other dependencies is important when system libraries or programs are needed. I've found it particularly useful in the context of C++ where, due to lack of widely adopted package managers, installing libraries matching required versions is cumbersome. Popular continuous integration platforms available to open source software usually offer solutions involving old GNU/Linux distributions and therefore make it difficult to install newer versions. In the C++ world where building applications from source is time consuming and often non-trivial, it's a major pain. But that's where Docker can help.

## C++ application built with Docker on CI

I'm working on a [C++ desktop client for Postgres](https://lchsk.com/sanchosql). I want to build and run the tests automatically after pushing my changes. Some of the dependencies, however, are heavy (e.g. GTK+ and its C++ bindings) and TravisCI offers Ubuntu 14.04 where only older versions are available. Fortunately, it can be built in a Docker container where operating system can be picked and libraries can be installed.

`.travis.yml` config file becomes very simple in this case as it only builds the image:

```yaml
language: cpp
sudo: false

jobs:
  include:
    - stage: ubuntu1804
      script:
        - cd ci
        - docker build -t sancho_ubuntu1804 -f Dockerfile.ubuntu1804 ./
```

`Dockerfile` is located in the `ci/` directory - it's currently designed to work with recent stable version of Ubuntu - 18.04. 

```dockerfile
FROM ubuntu:18.04
```

Libraries are easily installed with Ubuntu's package manager:

```dockerfile
RUN apt-get update && apt-get install -y \
    pkg-config \
    git \
    g++ \
    cmake \
    libxml2-utils \
    libgtkmm-3.0-dev \
    libgtksourceviewmm-3.0-dev \
    libpqxx-dev
```

Minor complication is that we need to get the `GoogleTest` library by installing it from source:

```dockerfile
RUN git clone https://github.com/google/googletest.git /googletest \
    && mkdir -p /googletest/build \
    && cd /googletest/build \
    && cmake .. && make && make install \
    && cd / && rm -rf /googletest
```

Afterwards, we just need to clone the project:

```dockerfile
RUN git clone https://github.com/lchsk/sanchosql.git /sanchosql
```

Then, we're ready to build the application and tests:

```dockerfile
RUN echo "Building the application" \
    && cd /sanchosql \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j

RUN echo "Building tests" \
    && cd /sanchosql/tests \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j
```

If they are built successfully, the last step is simply running the tests:

```dockerfile
RUN echo "Running tests" \
    && cd /sanchosql/tests/build \
    && ctest
```

This solution can also be easily tested locally.

```bash
cd ci
docker build -t sancho_ubuntu1804 -f Dockerfile.ubuntu1804 ./
```

This will build the application and run tests.

We can then run

```bash
docker run --rm -P -it --name sancho_build sancho_ubuntu180
```

to open shell and manually check if things look right inside the container by navigating to the application's directory:

```bash
cd /sanchosql
```

This solution is easily adaptable to various use cases and can be extended to more complex applications.

- [Learn more about SanchoSQL, a desktop client application for PostgreSQL](https://lchsk.com/sanchosql)
- [Source code](https://github.com/lchsk/sanchosql)
