Q = require 'q'
mysql = require 'mysql'
program = require 'commander'
durations = require 'durations'

# Wait for MySQL to become available
waitForMysql = (config) ->
  deferred = Q.defer()

  # timeouts in milliseconds
  connectTimeout = config.connectTimeout
  totalTimeout = config.totalTimeout

  quiet = config.quiet

  watch = durations.stopwatch().start()
  connectWatch = durations.stopwatch()

  attempts = 0
  pool = mysql.createPool config

  # Recursive connection test function
  testConnection = ->
    attempts += 1
    connectWatch.reset().start()
    pool.getConnection (error, client) ->
      if error?
        console.log "[#{error}] Attempt #{attempts} timed out. Time elapsed: #{watch}" if not quiet
        if watch.duration().millis() > totalTimeout
          connectWatch.stop()
          console.log "Could not connect to MySQL." if not quiet
          pool.end (error) ->
            console.log "Error shutting down the MySQL connection pool." if not quiet
          deferred.resolve 1
        else
          totalRemaining = Math.min connectTimeout, Math.max(0, totalTimeout - watch.duration().millis())
          connectDelay = Math.min totalRemaining, Math.max(0, connectTimeout - connectWatch.duration().millis())
          setTimeout testConnection, connectDelay
      else
        connectWatch.stop()
        if config.query?
          queryString = config.query
          console.log "Connected. Running test query: '#{queryString}'"
          client.query queryString, (error, rows) ->
            console.log "Query done."
            client.release()
            if (error)
              console.log "[#{error}] Attempt #{attempts} query failure. Time elapsed: #{watch}" if not quiet
              if watch.duration().millis() > totalTimeout
                console.log "MySQL test query failed." if not quiet
                deferred.resolve 1
              else
                totalRemaining = Math.min connectTimeout, Math.max(0, totalTimeout - watch.duration().millis())
                connectDelay = Math.min totalRemaining, Math.max(0, connectTimeout - connectWatch.duration().millis())
                setTimeout testConnection, connectDelay
            else
              watch.stop()
              console.log "Query succeeded. #{attempts} attempts over #{watch}"
              pool.end (error) ->
                console.log "Error shutting down the MySQL connection pool." if not quiet
              deferred.resolve 0
        else
          watch.stop()
          console.log "Connected. #{attempts} attempts over #{watch}"
          client.release()
          pool.end (error) ->
            console.log "Error shutting down the MySQL connection pool." if not quiet
          deferred.resolve 0

  testConnection()

  deferred.promise

# Script was run directly
runScript = () ->
  program
    .option '-D, --database <db_name>', 'MySQL database (default is mysql)'
    .option '-h, --host <hostname>', 'MySQL host (default is localhost)'
    .option '-i, --insecure-auth', 'Use insecure auth method (default is secure method)'
    .option '-p, --port <port>', 'MySQL port (default is 3306)', parseInt
    .option '-P, --password <password>', 'MySQL user password (default is empty)'
    .option '-q, --quiet', 'Silence non-error output (default is false)'
    .option '-Q, --query <query_string>', 'Custom query to confirm database state'
    .option '-t, --connect-timeout <milliseconds>', 'Individual connection attempt timeout (default is 250)', parseInt
    .option '-T, --total-timeout <milliseconds>', 'Total timeout across all connect attempts (dfault is 15000)', parseInt
    .option '-u, --username <username>', 'Posgres user name (default is mysql)'
    .parse(process.argv)

  config =
    host: program.host ? 'localhost'
    port: program.port ? 3306
    user: program.username ? 'mysql'
    password: program.password ? ''
    database: program.database ? 'mysql'
    totalTimeout: program.totalTimeout ? 15000
    query: program.query ? null
    quiet: program.quiet ? false
    insecureAuth: program.insecureAuth ? false
    acquireTimeout: program.connectTimeout ? 250
    connectTimeout: program.connectTimeout ? 250
    connectionLimit: 1
    queueLimit: 1
    waitForConnections: false

  waitForMysql(config)
  .then (code) ->
    process.exit code

# Module
module.exports =
  await: waitForMysql
  run: runScript

# If run directly
if require.main == module
  console.log "Running the script..."
  runScript()

