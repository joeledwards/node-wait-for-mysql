
Wait for MySQL
===========

Waits for a MySQL connection to become available, optionally running
a custom query to determine if the connection is valid.

Installation
============

```bash
npm install --save wait-for-mysql
```

Usage
=====

Run as a module within another script:

```coffeescript
waitForMy = require 'wait-for-mysql'
config =
  username: user
  password: pass
  quiet: true
  query: 'SELECT 1'

waitForMy.wait(config)
```
      

Or run stand-alone

```bash
wait-for-mysql --username=user --password=pass --quiet
```

Building
============

cake build

