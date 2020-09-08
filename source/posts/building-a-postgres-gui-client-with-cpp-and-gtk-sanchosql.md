---
title: Building a Postgres GUI client with C++ and GTK (SanchoSQL)
created: 2019-06-09T00:00:00Z
description: SanchoSQL - Postgres GUI client with C++ and GTK
keywords: c++, sanchosql, sql, sancho, postgres, databases, gui, gtk, gtkmm, gtk+
---

I've recently published version 0.1 of SanchoSQL, a GUI client for PostgreSQL. It's written in C++ and designed for Linux systems. It has a [website](https://lchsk.com/sanchosql "SanchoSQL website") and is [open source](https://github.com/lchsk/sanchosql "SanchoSQL Postgres client for Linux").

## Why

There aren't many Postgres GUI clients developed for Linux. Those available are usually heavy and bloated. I was looking for a minimalistic option that works fast and has a simple and intuitive interface. I wanted to build one for myself so that it includes features I need and is as small as possible.

<a href="./data/projects/sanchosql.png"><img src="./data/projects/sanchosql.png" alt="SanchoSQL SQL editor view"/></a>

## C++ and GTK

I chose C++ and GTK (with GTKmm bindings) for this project which may seem not such a great idea. Writing C++ arguably slows down the pace of delivery compared to scripting languages. The interface could probably look more modern and offer more features if it used web technologies. GTK, in particular, feels old-fashioned and a bit clunky. However, I like to look at it differently. I believe that an application that's close to a user (such as a desktop program that someone needs to install on their computer) needs to be efficient and offer the best possible performance. Compared to, e.g. server-side software, authors of desktop applications face extra challenges. They can't improve infrastructure and can't constantly measure user activity to fix performance bottlenecks. If someone decides to run the program on a cheap laptop, their experience will be poor. Similarly, there's no way to tell how a user will be using the software. One may, for example, open huge files and attempt to process a lot of data. C++ is not, of course, a solution too all those problems. It does, however, offer great performance out of the box and tools to further improve it.

## Features

The application has two ways of looking at data. First option is to use the UI to navigate to the table/view or other database objects to see them. For instance, to see data in a table, you can double click on a table name. Data is presented in a columnar view with column names and types in headers. You can easily work with many tables, as each one is open on a separate tab.

This view is quite flexible and makes it easy to update and search for specific values. 

Values can be updated by simply double clicking on a row, changing a value and committing the transaction. Adding and deleting rows is also possible from UI. 

<a href="./data/projects/sanchosql_table_view_2.png"><img src="./data/projects/sanchosql_table_view_2.png" alt="SanchoSQL editing values in UI"/></a>

At the top, there are two extra fields that can be used to list just the columns you need to see (useful in case of tables with a lot of columns). Text field below allows to apply extra SQL filtering to the results (think `WHERE` conditions).

User can view information about a table, including details such as columns and their types, as well as constraints and indices.

<a href="./data/projects/sanchosql_table_schema.png"><img src="./data/projects/sanchosql_table_schema.png" alt="SanchoSQL Postgres table schema"/></a>

Apart from tables, users can see views, triggers, functions, and sequences.

Alternative way of browsing the database, useful especially for advanced users, is the "editor" view, where a user can type SQL commands directly and see the results. The editor supports some of the standard features you would expect, such as syntax highlighting. Apart from just executing SQL code, users can also see query plans to compare performance of their code.

## Setup

At the moment, the desktop application is split into several libraries that are later statically built into a single binary file. The whole process is defined in CMake. The goal of this separation was to allow working on parts of the codebase that don't need to depend on each other. For instance, UI and database implementations are separated. I would like the split to be cleaner, as currently there are quite a few dependencies, e.g. database abstraction is coupled with the Postgres database communication.

In an application like this, it's useful to have a clear distinction between the implementation, and the user interface, so that it's possible to build different UIs that can easily implement the same functionality. At the current stage of this project, it would require some extra work to more clearly split the interface from the implementation.

## Summary

Building desktop applications for Linux systems is still not as easy as for proprietary systems. One has to battle quite a few differences between different distributions (for instance, when packaging the application and managing the dependencies). There are inconsistencies in the UI, depending on desktop environments, that aren't always easy to fix. Also, help available online for GTK is quite limited and often not up-to-date, which obviously doesn't make it easier.

At the current stage, SanchoSQL offers a simple and minimalistic Postgres client. It's also ready for further improvements in terms of user interface and features.
