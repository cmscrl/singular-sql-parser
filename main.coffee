SingularSqlParser = require './SingularSqlParser'

parser = new SingularSqlParser()

try
    console.log parser.parse process.argv[2], process.argv[3]
catch e
    console.log "Failed to parse: #{e}"
