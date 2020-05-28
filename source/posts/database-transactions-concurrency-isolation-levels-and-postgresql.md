---
title: Database transactions, concurrency, isolation levels, and PostgreSQL
created: 2020-05-27T00:00:00Z
description: Behavior of concurrent access to resources such as databases can be a complex topic. This article describes how concurrent access can be managed using SQL transactions, including transaction isolation levels, and how certain patterns of access can affect performance.
keywords: postgres, postgresql, isolation levels, transaction isolation levels, concurrency, concurrent transactions, database performance, read committed, repeatable read, serializable transactions, read uncommitted transactions, acid transactions, atomic transactions, postgres transactions, sql transactions, isolation levels
---

More:

- See results of benchmarking concurrent operations in Postgres: {{@benchmarking-concurrent-operations-in-postgresql}}

Services providing users with data must ensure the information they show is in a valid state. With many users accessing and modifying data at the same time, ensuring the correctness of data is no easy task. One of the main reasons we use databases is to take advantage all the hard work that had already gone into ensuring data consistency in those systems. However, even though a lot of difficult problems had already been solved for the users of databases, it's still important to know when to use different database features and how they can impact performance of the entire database system. Concurrent updates, `select for update` queries, transaction isolation levels all impact the behavior and performance of the database.

## Transactions

Transactions are a mechanism to move the data from one consistent, valid state into another. This includes the ability to handle potential failures and many concurrent users at the same time who can try accessing or modifying the same data. In either case, a database can never allow itself to end up in an invalid state, e.g. by saving the results of only a part of a transaction, or allowing values to be invalid due to many users modifying them at the same time. In case of PostgreSQL, almost every interaction with it, is a part of a transaction, including simple single line `select` queries. However, a good implementation of transactions really shines in case of concurrent use of the database by many users. A database might be asked to handle thousands of transactions while preserving the data in a valid state. 

Transactions are usually described to have "ACID" properties, i.e. are:

- atomic (a transaction is treated wholly; if a single query within a transaction fails, then the entire transaction fails),

- consistent (all existing constraints of the data model are respected),

- isolated (from other transactions),

- durable (results are saved to disk).

The concept of isolation is especially interesting, and will be explained in more detail later. The way concurrent transactions are interacting with each other can be modified.

The examples presented in the article were tested with PostgreSQL 12.3 using the `psql` utility.

## Locking

Importantly, transactions and certain operations performed within them, can block each other due to locking mechanisms necessary to keep the data safe. This can have massive performance implications.. It's worth noting when a lock occurs and its scope (e.g. the entire table, a subset of rows, or just a single row).

In general, multiple users can read the current state of data without blocking each other. Consider two users interacting with the database in their own transactions:

{{#include posts/html/postgres_txn/table_1.html}}

Reading is still possible even if another user is currently modifying the data.

{{#include posts/html/postgres_txn/table_2.html}}

In this scenario, User 1 sets the `value` to 200 in their own transaction (line 2). User 2 can still read the same row (`id = 1`) even though User 1 hasn't committed their transaction yet. However, the crucial distinction is what value does User 2 see at that point (line 3). It's 100, i.e. the "old" value (as the change to 200 hasn't been committed yet). This occurs due to the database maintaining each transaction isolated and disallowing "dirty reads", i.e. reads that haven't been committed yet. Those are never allowed in PostgreSQL. At the same time (line 3), User 1 sees 200, i.e. "their" value from within their own transaction. User 2 will only see the new value after User 1 commits their transaction which happens in line 4.

The isolation also works if multiple users are modifying the same data. Let's set value to 0 (`update b set value = 0 where id = 1`). Now, let's make both users try to increment `value`.

{{#include posts/html/postgres_txn/table_3.html}}

In this example, both users are trying to increment the value of single row identified by `id = 1`. We expect the result of this to be 2. User 1 increments the value by 1 and sees the current value to be equal to 1. Meanwhile, User 2 still sees value = 0, and tries to increment it by 1 in their own transaction. However, that operation is not permitted to continue because User 1 still holds the lock on the row with `id = 1` and will hold that lock until the transaction is committed or rolled back. Thus, the database ensures the data does not get corrupted due to concurrent updates. After both users commit their transactions, they will both see `value = 2`, as one would expect. 

This behavior is impacted by the transaction isolation level which will be described later. It occurs at the "read committed" level (a default in PostgreSQL) but not at higher levels.

The locking mechanism ensures the data won't get corrupted but it has performance implications. Keeping transactions open run for a long time can significantly affect performance. In the example above, we've locked only one row due to the `where id = 1` condition. So if User 2 was instead modifying a row with `id = 2` both transactions would avoid blocking. However, an `update` could affect more rows (even the entire table), in which case a lock would be held on all selected rows.

## `Select for update`

While `update` locks rows for the time needed to perform a change to the data, sometimes you may need to lock rows for a bit longer, perhaps to perform additional processing. To prevent race conditions in that case, `select for update` can be used. It locks selected rows and blocks queries that could affect selected data (such as other `select for update` or `update`).

{{#include posts/html/postgres_txn/table_4.html}}

After User 1 acquires a lock on row with `id = 1` in line 2, only they have a right to modify it. In line 3 User 2 tries to lock the same row but they have to wait (operations in that transaction cannot proceed) until User 1 finishes their transaction (line 5). After that User 2 is given a lock on `id = 1`.

All this locking and waiting can be expensive and result in lower performance. 

Sometimes waiting is not necessary and all we want to do is to acquire whatever available (unlocked) row we get can get. In that scenario, we won't be waiting but also are not guaranteed to get anything. If all rows are locked, we'll get an empty result set. This behavior can be achieved in Postgres with `skip locked` instruction.

Let's say we have 100 rows in table C.

{{#include posts/html/postgres_txn/table_5.html}}

By using `for update skip locked` each user can get rows (different ones) without waiting for the other transaction to finish.

However, consider a case when there's nothing left because other users are holding locks on all available data:

{{#include posts/html/postgres_txn/table_6.html}}

User 1 requests 100 rows and locks them. User 2 attempts to get 1 row with a lock, however User 1 already has a lock on all available data. Due to `skip locked`, the query won't wait and return an empty set (without `skip locked` the query would be waiting for User 1 to finish).

## `Select for update` and foreign keys

Using `select for update` is already expensive but it can get even more so. This is because not only the table we specify that will be locked but also tables related to it via foreign keys. This prevents breaking foreign key constraints but also adds to waiting times without being explicit about it, so worth being extra careful about using `select for update`.

Consider two tables, `d` and `e`. Table `e` holds a foreign key `d_id` to table `d`.

{{#include posts/html/postgres_txn/table_7.html}}

Even though User 1 acquires a lock on table `e`, User 2 won't be able to run a delete query for table `d` until User 1 finishes their transaction. This is because `e` has a foreign key to `d`, so deleting related rows from table `d` would break foreign key constraints in `e`. In a more complex data model this can be difficult to see and a `select for update` query could be more costly that it would seem.

## Transaction isolation levels

I've mentioned isolation in the context of ACID principles. In general, isolation describes the idea of concurrently running transactions that don't interfere with each other. However, the exact behavior of isolation is configurable. SQL describes four isolation levels (from the least to the most strict):

- read uncommitted,

- read committed,

- repeatable read,

- serializable.

Each level is defined in terms of phenomena it prohibits. "Read uncommitted" is the least strict, and is not even implemented by PostgreSQL. It allows "dirty reads", which means that transaction 1 could read values set by transaction 2 even before the latter has committed them. The data read by transaction 1 could be invalid, as transaction 2 could be rolled back, therefore reverting any changes. 

This behavior is prohibited by the "read committed" isolation level, which as the name suggests, will only ever read data that has been committed. It is the default level in PostgreSQL. Even though "read committed" adds extra level of safety, there's still a number of potentially unwanted, or unexpected anomalies. Let's look at "repeatable read" and "serializable" levels which add extra protection.

### "Repeatable read" isolation level

Similarly to the "read committed" level, it protects against "dirty reads". It also protects against additional phenomena that can occur in the concurrent use of a database, namely "lost updates", and "non-repeatable reads". In Postgres it also protects against "phantom reads" even though the SQL standard doesn't require it. Let's see examples of those anomalies.

### "Non-repeatable reads"

They can occur when values are read multiple times within the same transaction, and the obtained values are different due to another transaction modifying them (and committing the changes). So e.g. if the same query is executed twice within a transaction, it could return different values each time.

{{#include posts/html/postgres_txn/table_8.html}}

In this case (we're using the default "read committed" isolation level), user 1 queries the table and sees `value = 100` (line 2). Meanwhile, user 2 runs an `update` (line 3) in a transaction which changes the `value` to 1 and promptly commits that transaction (line 4). When user 1 tries to read the `value` again (line 5), it's now equal to 1. This behavior means that values read in a transaction are not stable and can be affected by other, concurrent transactions modifying them.

If we used "read committed" isolation level, this phenomenon won't occur, and user 1 will see `value = 100` in both reads. In the following example, we're explicitly defining the isolation level for User 1's transaction to be "repeatable read".

{{#include posts/html/postgres_txn/table_9.html}}

Now, after the same sequence of operations, user 1 will see `value = 100` twice even though it has been modified in the meantime by user 2. In general, with "repeatable read" isolation level, data that has been read is guaranteed to stay constant throughout the transaction, regardless of concurrent updates (unless, of course, it's modified *within* the transaction).

### "Lost updates"

Another anomaly prohibited by the "repeatable read" isolation level but permitted by "read committed" are the so called "lost updates". In case of multiple transactions updating the same piece of data, a "read committed" transaction will accept them every time whereas a "repeatable read" transaction will reject changes if the same piece of data has already been modified by another transaction.

{{#include posts/html/postgres_txn/table_10.html}}

In this example we have two users having differing opinions on what the `value` of the row with `id = 1` should be. They're setting it to different values in their respective transactions. In the end, each `update` will be recorded but because user 2 commits their value shortly after user 1, their `value = 99` will remain and user 1's value of 100 has been "lost".

Now let's try the same with the "repeatable read" transaction.

{{#include posts/html/postgres_txn/table_11.html}}

In this case, after user 1 sends a `commit` the value of 100 will be recorded and user 2's transaction won't be allowed to continue (it will return an error and only a rollback will be permitted). So with "repeatable read" transactions, concurrent modifications of the same data are not permitted.

### "Phantom reads"

They're similar to non-repeatable reads but the SQL standard allows them at the "repeatable read" isolation level. Interestingly, PostgreSQL doesn't, and at the "repeatable read" level Postgres already protects against them.

"Phantom read" can occur when data is read multiple times in a transaction while another transaction is adding or removing rows in the same table.

Let's first see how phantom reads could occur at the "read committed" level.

{{#include posts/html/postgres_txn/table_12.html}}

User 1 first counts rows in the table `b` (line 2, there's just 1 row). Meanwhile, user 2 has inserted (and committed) a new row into the table `b` (lines 3 and 4). After user 1 reads the count again (line 5) it will have changed and be equal to 2 due to user 2's recent insertion.

With a "repeatable read" transaction this won't occur.

{{#include posts/html/postgres_txn/table_13.html}}

After a similar set of actions, when user 1 reads the count again (line 5) it won't have changed despite user 2's insertion.

### Serializable transactions

The most strict isolation level prohibits phantom reads (in SQL standard, they're already prohibited at "repeatable read" level in Postgres). Additionally, at serializable level, a user can expect that concurrent transactions would have the same effect as if they were applied serially, one after another. This requirement allows to catch complex cases where dependencies between concurrent transactions are introduced.

First, table `b` looks like this:

{{#include posts/html/postgres_txn/table_14.html}}

Let's consider an example, first at "repeatable read" level.

{{#include posts/html/postgres_txn/table_15.html}}

Repeatable read transactions will allow both users to commit even though after User 1 inserts the sum, User 2's sum is no longer correct.

Consider the same scenario but with serializable transactions.

{{#include posts/html/postgres_txn/table_16.html}}

In this case, User 1 can successful commit, but if User 2 tries to do it, they will get an error:

```
ERROR:  could not serialize access due to read/write dependencies among transactions
DETAIL:  Reason code: Canceled on identification as a pivot, during commit attempt.
HINT:  The transaction might succeed if retried.
```

The transaction won't be committed. As the error suggests, retrying the transaction might work (assuming there won't be another concurrent transaction such as User 1's). Importantly, if user 2 retried, a different value would be inserted (as the result of the sum query would have been different considering user 1's already committed insert). 

The error warns about `read/write dependencies among transactions`. It's what serializable transactions protect against as they ensure that concurrent transactions are performed as if they were applied one after another, without dependencies between transactions.

The error also mentions another issue that application developers dealing with "repeatable read" and serializable transactions must be aware of. Transactions can fail due to additional checks protecting against concurrent updates but may succeed if tried again. Applications need to be prepared to handle those cases.

## Summary

Behavior of concurrent access to resources such as databases can be a complex topic. This article describes how concurrent access can be managed using SQL transactions, including transaction isolation levels, and how certain patterns of access can affect performance.
