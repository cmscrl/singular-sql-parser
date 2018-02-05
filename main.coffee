Lexer = require './Lexer'
Parser = require './Parser'

parser = new Parser()
lexer = new Lexer()

if not process.argv[2]?
    console.log "Command-line syntax:\n    npm start <select-statement> [<table-name>]\nwhere:\n    <select-statement>  the Singular SQL statement to parse\n    <table-name>        if specified, parses the statement into correct SQL syntax applied to table with name <table-name>"
else if process.argv[3]?
    try
        console.log parser.toSQL process.argv[2], process.argv[3]
    catch e
        console.log "Failed to parse: #{e}"
else
    try
        console.log parser.parse process.argv[2]
    catch e
        console.log "Failed to parse: #{e}"