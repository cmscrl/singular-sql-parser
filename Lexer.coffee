Chevrotain = require 'chevrotain'

class Lexer

    lexer = null

    createToken = (name, pattern, group, lineBreaks) ->
        token =
            name : name
            pattern : pattern

        if group?
            token.group = group

        if lineBreaks?
            token.line_breaks = lineBreaks

        return Chevrotain.createToken token

    @symbols =
        all : createToken 'all', /all(?!\w)/i
        as : createToken 'as', /as(?!\w)/i
        binaryOperator : createToken 'binaryOperator', /\|(\|)?|\*|\/|%|\+|-|<(<|=|>)?|>(>|=)?|&|=(=)?|\!=|(is|in|like|glob|match|regexp|and|or)(?!\w)/i
        comma : createToken 'comma', /,/
        distinct : createToken 'distinct', /distinct(?!\w)/i
        groupby : createToken 'groupby', /group by(?!\w)/i
        having : createToken 'having', /having(?!\w)/i
        identifier : createToken 'identifier', /([a-zA-Z_][a-zA-Z0-9_]*)|("([^"]|"")+")(?!\w)|`([^`]|``)+`(?!\w)/
        lparen : createToken 'lparen', /\(/
        numericLiteral : createToken 'numericLiteral', /0x(\d|[ABCDEF])+|((\d+(\.\d*)?)|(\.\d+))(E(\+|-)?\d+)?(?!\w)/i
        nullLiteral : createToken 'nullLiteral', /null(?!\w)/i
        rparen : createToken 'rparen', /\)(?!\w)/
        select : createToken 'select', /select(?!\w)/i
        star : createToken 'star', /\*(?!\w)/
        stringLiteral : createToken 'stringLiteral', /'([^']|'')+'(?!\w)/
        unaryOperator : createToken 'unaryOperator', /~|not(?!\w)/i
        unaryOrBinaryOperator : createToken 'unaryOrBinaryOperator', /-|\+/
        where : createToken 'where', /where(?!\w)/i
        whitespace : createToken 'whitespace', /\s+/, Chevrotain.Lexer.SKIPPED, true

    @tokens = [
        @symbols.whitespace
        @symbols.select
        @symbols.where
        @symbols.groupby
        @symbols.having
        @symbols.as
        @symbols.all
        @symbols.distinct
        @symbols.comma
        @symbols.lparen
        @symbols.rparen
        @symbols.star
        @symbols.unaryOrBinaryOperator
        @symbols.unaryOperator
        @symbols.binaryOperator
        @symbols.nullLiteral
        @symbols.numericLiteral
        @symbols.stringLiteral
        @symbols.identifier
    ]

    instance = () ->
        lexer ?= new Chevrotain.Lexer Lexer.tokens
        
        return lexer

    @tokenize = (statement) ->
        return instance().tokenize statement

module.exports = Lexer