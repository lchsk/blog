---
title: Launching applications from Emacs
created: 2018-08-27T00:00:00Z
description: 
keywords: c, list, emacs lips, elisp, terminal, application launcher, xstarter, emacs, linux application launcher
---

I spent a lot of time in Emacs so I'm always looking for something new to add to my workflow. I typically start applications using [**xstarter**](https://github.com/lchsk/xstarter), a command line tool written in C that uses an [ncurses](https://www.gnu.org/software/ncurses/) interface. It allows me to quickly search an open programs I need. One of its useful features is recording applications that were recently opened and showing them on the screen so that they can be accessed quickly. Most of the time, I use it via [`xmonad` window manager](https://xmonad.org/) where it's configured to launch with a [key shortcut](https://github.com/lchsk/dotfiles/blob/master/xmonad.hs#L133).

<a href="./data/xstarter_2.png"><img src="./data/xstarter_2.png" alt="List of recently opened applications in terminal"/></a>

*List of recently opened applications in terminal*

However, I also wanted to have access to that tool via Emacs so that I can use it even if I'm not running `xmonad`. I wrote a small [**Emacs Lisp** package](https://github.com/lchsk/helm-xstarter) that offers an interface for **xstarter**. It uses [Helm](https://github.com/emacs-helm/helm), a great framework for building convenient search interfaces that many Emacs users are familiar with.

<a href="./data/helm_xstarter.png"><img src="./data/helm_xstarter.png" alt="Emacs interface for xstarter"/></a>

*Emacs interface for `xstarter`*

In order to make it work, I had to add two additional features to `xstarter` itself. Firstly, it needs to return a list of applications it has stored in cache. It's printed to the standard output; in order to get it, the Lisp package simply runs `xstarter -P` as a shell command and collects the output as a string. Secondly, I've added `xstarter -e` option which can launch any application in a separate process (so if it's run from a terminal, it's detached from it). The ELisp package uses that command to launch an application selected by a user in the Emacs interface:

```lisp
(defun helm-xstarter-open (arg)
  (shell-command (concat "xstarter -e" arg)))
```

It's surprisingly short at just over [20 lines of code](https://github.com/lchsk/helm-xstarter/blob/master/helm-xstarter.el)!

[**Source on github**](https://github.com/lchsk/helm-xstarter/)
