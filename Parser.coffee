Chevrotain = require 'chevrotain'
Lexer = require './Lexer'

class Parser

    class SingularSQLParser extends Chevrotain.Parser

        constructor : () ->
            super [], Lexer.tokens

            @grammar()

            Chevrotain.Parser.performSelfAnalysis this

        grammar : () =>
            @RULE 'selectCore', () =>
                statement = "#{@CONSUME(Lexer.symbols.select).image} "

                @OPTION1 () =>
                    @OR [
                        {
                            ALT : () =>
                                statement += "#{@CONSUME(Lexer.symbols.all).image} "
                        }
                        {
                            ALT : () =>
                                statement += "#{@CONSUME(Lexer.symbols.distinct).image} "
                        }
                    ]
                    
                values = []
                columns = []

                @AT_LEAST_ONE_SEP1
                    SEP : Lexer.symbols.comma,
                    DEF : () =>
                        rule = @SUBRULE @resultColumn

                        values.push rule.statement
                        columns.push rule.column

                statement += values.join ', '

                if @table?
                    statement += " FROM #{@table}"

                @OPTION2 () =>
                    statement += " #{@CONSUME(Lexer.symbols.where).image}"
                    statement += " #{@SUBRULE1 @exprCore}"

                @OPTION3 () =>
                    statement += " #{@CONSUME(Lexer.symbols.groupby).image} "

                    values = []

                    @AT_LEAST_ONE_SEP2
                        SEP : Lexer.symbols.comma,
                        DEF : () =>
                            values.push @SUBRULE2 @exprCore

                    statement += values.join ', '

                    @OPTION4 () =>
                        statement += " #{@CONSUME(Lexer.symbols.having).image}"
                        statement += " #{@SUBRULE3 @exprCore}"

                result =
                    statement : statement
                    columns : columns

                return result

            @RULE 'resultColumn', () =>
                statement = ''
                column = ''

                @OR [
                    {
                        ALT : () =>
                            statement = @SUBRULE @exprCore
                            column = statement

                            @OPTION () =>
                                statement += " #{@CONSUME(Lexer.symbols.as).image}"

                                column = @CONSUME(Lexer.symbols.identifier).image

                                statement += " #{column}"
                    }
                    {
                        ALT : () =>
                            statement = @CONSUME(Lexer.symbols.star).image
                            column = statement
                    }
                ]

                result =
                    statement : statement
                    column : column

                return result

            @RULE 'exprCore', () =>
                result = @SUBRULE1 @expr

                @MANY () =>
                    @OR [
                        {
                            ALT : () =>
                                result += " #{@CONSUME(Lexer.symbols.binaryOperator).image}"
                        }
                        {
                            ALT : () =>
                                result += " #{@CONSUME(Lexer.symbols.star).image}"
                        }
                        {
                            ALT : () =>
                                result += " #{@CONSUME(Lexer.symbols.unaryOrBinaryOperator).image}"
                        }
                    ]

                    result += " #{@SUBRULE2 @expr}"

                return result

            @RULE 'expr', () =>
                result = ''

                @OR [
                    {
                        ALT : () =>
                            result = "#{@CONSUME(Lexer.symbols.unaryOperator).image}"
                            result += " #{@SUBRULE1 @expr}"
                    }
                    {
                        ALT : () =>
                            result = "#{@CONSUME(Lexer.symbols.unaryOrBinaryOperator).image}"
                            result += " #{@SUBRULE2 @expr}"
                    }
                    {
                        ALT : () =>
                            result = @SUBRULE @literalValue
                    }
                    {
                        ALT : () =>
                            result = @CONSUME(Lexer.symbols.identifier).image

                            @OPTION () =>
                                result += " #{@CONSUME1(Lexer.symbols.lparen).image} "

                                values = []

                                @MANY_SEP 
                                    SEP : Lexer.symbols.comma
                                    DEF : () =>
                                        values.push @SUBRULE1 @exprCore

                                result += values.join ', '

                                result += " #{@CONSUME1(Lexer.symbols.rparen).image}"
                    }
                    {
                        ALT : () =>
                            result = "#{@CONSUME2(Lexer.symbols.lparen).image} "

                            values = []

                            @AT_LEAST_ONE_SEP
                                SEP : Lexer.symbols.comma
                                DEF : () =>
                                    values.push @SUBRULE2 @exprCore

                            result += values.join ', '

                            result += " #{@CONSUME2(Lexer.symbols.rparen).image}"
                    }
                ]

                return result

            @RULE 'literalValue', () =>
                result = ''

                @OR [
                    {
                        ALT : () =>
                            result = @CONSUME(Lexer.symbols.numericLiteral).image
                    }
                    {
                        ALT : () =>
                            result = @CONSUME(Lexer.symbols.stringLiteral).image
                    }
                    {
                        ALT : () =>
                            result = @CONSUME(Lexer.symbols.nullLiteral).image
                    }
                ]

                return result

    parser = new SingularSQLParser()

    @parse = (statement) ->
        parser.input = Lexer.tokenize(statement).tokens
        parser.table = null

        result = parser.selectCore()

        if parser.errors.length > 0
            throw parser.errors

        return result

    @toSQL = (statement, table = '"table"') ->
        parser.input = Lexer.tokenize(statement).tokens
        parser.table = table

        result = parser.selectCore()

        if parser.errors.length > 0
            throw parser.errors

        return result

module.exports = Parser