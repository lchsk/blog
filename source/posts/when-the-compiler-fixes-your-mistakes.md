---
title: When the compiler fixes your mistakes
created: 2018-06-24T00:00:00Z
description: I have been working on a new feature for my terminal-based application launcher. I want to be able to search for programs and run them from within Emacs using xstarter. In this post, I'll describe a strange experience I have had fixing a bug.
keywords: compilers, c, terminal, application launcher, xstarter, emacs, bugs, debugging, warnings
---

I have been working on a new feature for my [terminal-based application launcher](https://github.com/lchsk/xstarter). The feature itself is not important at this point although I'm happy to mention that I'm working on integrating the application launcher with Emacs. I want to be able to search for programs and run them from within Emacs using [xstarter](https://xstarter.org). So far, I've begun making changes to the application but I'm yet to build the Emacs interface. However, what I wanted to write about in this post, is the strange experience I have had fixing a bug.

## Good intentions

Whilst preparing to make changes, I have noticed this piece of code [I had written some time ago](https://github.com/lchsk/xstarter/blob/v0.7.0/src/utils.c#L46).

```
    char path_cpy[1024];
    strcpy(path_cpy, path);

    record_open_file(path_cpy);
```

Forgive the use of `strcpy` and a magic number; the problem was that I didn't remember why I was creating a copy of `path` and passing it into `record_open_file()`. Sadly, there was no comment. I've quickly changed the call to just `record_open_file(path);` and later used `path` instead of `path_cpy`. And that's where strange things began to happen. 

When I tried to test it, a different program than the one I had selected would be launched. Usually, the one next to it in the list, but that wasn't really helpful. I wanted to see what's happening in the debugger, so I've built the application using debugging configuration (`cmake -DCMAKE_BUILD_TYPE=Debug .`). 

When I've stopped at a breakpoint in `record_open_file()`, I've noticed what the issue was: `path` was pointing at an element in `recent_apps` array, which elements were in turn referenced by the `results` array, used to present the applications list to a user. Turns out, elements in `recent_apps` can be slightly shifted (by one element, actually) when a new entry is being added. This is to be able to show the most recently launched program at the top. So the cause of this was a few mutable data structures referencing each other in a non-transparent way. 

But that was not the end. When I've tried to start any application, it wouldn't work at all.

## Listen to your compiler

I have removed the code changes I've made when testing but that did not help. Clearly, another issue was lurking somewhere outside of the code. 

I remembered I've built the program for debugging. I've checked what compiler flags I'm passing in that case. Debugging version was not using any optimisation flags and the release one had `-O3` in the build configuration. In a debugging version I had a few warnings that I haven't fixed. Some of them looked particularly gravely:

```
/home/lchsk/git/xstarter/src/utils.c:103:21:
warning: passing argument 1 of strncpy 
from incompatible pointer type 
[-Wincompatible-pointer-types]
             strncpy(args[0], path_cpy, STR_SIZE);
                     ^~~~
In file included from /home/lchsk/git/xstarter/src/utils.c:7:0:
/usr/include/string.h:124:14:
note: expected char * restrict 
but argument is of type char (*)[(sizetype)STR_SIZE]
extern char *strncpy (char *__restrict __dest,
              ^~~~~~~
```

It looked bad and pointed to a reason why the debugging version was not working. But why the release build was fine? Well, the release configuration was using the optimisation flag (`-O3`) and the compiler was able to fix the bug while applying optimisations, so the code was working as expected and the warning above was now showing up. All of that thanks to the compiler which was able to figure out what the intention of the code was (even with just `-O1` flag).

Later, I fixed the code that the compiler was complaining about when `-O0` flag was on. Essentially, I've changed the definition using arrays 

`char (*args[args_cnt])[STR_SIZE];` 

to 

`char **args = smalloc(args_cnt * sizeof(char*));` 

in order to avoid passing arrays and instead using pointers directly.

Compiler warnings can clearly be indispensable and ignoring them can not only lead to broken programs but also cause headaches when debugging applications built with various configurations.
