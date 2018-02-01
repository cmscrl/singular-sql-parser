Chevrotain = require 'chevrotain'

class SingularSqlParser extends Chevrotain.Parser

    constructor : () ->
        all = Chevrotain.createToken
            name : 'all'
            pattern : /all(?!\w)/i

        as = Chevrotain.createToken
            name : 'as'
            pattern : /as(?!\w)/i
        
        binaryOperator = Chevrotain.createToken
            name : 'binaryOperator'
            pattern : /\|(\|)?|\*|\/|%|\+|-|<(<|=|>)?|>(>|=)?|&|=(=)?|\!=|(is|in|like|glob|match|regexp|and|or)(?!\w)/i

        comma = Chevrotain.createToken
            name : 'comma'
            pattern : /,/

        distinct = Chevrotain.createToken
            name : 'distinct'
            pattern : /distinct(?!\w)/i

        groupby = Chevrotain.createToken
            name : 'groupby'
            pattern : /group by(?!\w)/i

        having = Chevrotain.createToken
            name : 'having'
            pattern : /having(?!\w)/i

        identifier = Chevrotain.createToken
            name : 'identifier'
            pattern : /([a-zA-Z_][a-zA-Z0-9_]*)|("([^"']|'')+")(?!\w)|`([^"']|'')+`(?!\w)/

        lparen = Chevrotain.createToken
            name : 'lparen'
            pattern : /\(/

        numericLiteral = Chevrotain.createToken
            name : 'numericLiteral',
            pattern : /0x(\d|[ABCDEF])+|((\d+(\.\d*)?)|(\.\d+))(E(\+|-)?\d+)?(?!\w)/i

        nullLiteral = Chevrotain.createToken
            name : 'nullLiteral'
            pattern : /null(?!\w)/i

        rparen = Chevrotain.createToken
            name : 'rparen'
            pattern : /\)(?!\w)/

        select = Chevrotain.createToken
            name : 'select'
            pattern : /select(?!\w)/i

        star = Chevrotain.createToken
            name : 'star'
            pattern : /\*(?!\w)/

        stringLiteral = Chevrotain.createToken
            name : 'stringLiteral'
            pattern : /'([^']|'')+'(?!\w)/

        suffixOperator = Chevrotain.createToken
            name : 'suffixOperator'
            pattern : /(isnull|notnull)(?!\w)/i
        
        unaryBinaryOperator = Chevrotain.createToken
            name : 'unaryBinaryOperator'
            pattern : /-|\+/

        unaryOperator = Chevrotain.createToken
            name : 'unaryOperator'
            pattern : /~|not(?!\w)/i

        where = Chevrotain.createToken
            name : 'where'
            pattern : /where(?!\w)/i

        whitespace = Chevrotain.createToken
            name : "whitespace",
            pattern : /\s+/,
            group : Chevrotain.Lexer.SKIPPED,
            line_breaks : true

        tokens = [
            whitespace
            select
            where
            groupby
            all
            distinct
            having
            comma
            as
            lparen
            rparen
            suffixOperator
            star
            unaryBinaryOperator
            binaryOperator
            unaryOperator
            nullLiteral
            numericLiteral
            stringLiteral
            identifier
        ]

        super [], tokens

        @lexer = new Chevrotain.Lexer tokens

        @RULE 'selectCore', () =>
            statement = "#{@CONSUME(select).image} "

            @OPTION1 () =>
                @OR [
                    {
                        ALT : () =>
                            statement += "#{@CONSUME(all).image} "
                    }
                    {
                        ALT : () =>
                            statement += "#{@CONSUME(distinct).image} "
                    }
                ]

            values = []
            columns = []

            @AT_LEAST_ONE_SEP1
                SEP : comma,
                DEF : () =>
                    rule = @SUBRULE @resultColumn

                    values.push rule.statement
                    columns.push rule.column

            statement += values.join ', '

            if @table?
                statement += " FROM #{@table}"

            @OPTION2 () =>
                statement += " #{@CONSUME(where).image}"
                statement += " #{@SUBRULE1 @exprCore}"

            @OPTION3 () =>
                statement += " #{@CONSUME(groupby).image} "

                values = []

                @AT_LEAST_ONE_SEP2
                    SEP : comma,
                    DEF : () =>
                        values.push @SUBRULE2 @exprCore

                statement += values.join ', '

                @OPTION4 () =>
                    statement += " #{@CONSUME(having).image}"
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
                            statement += " #{@CONSUME(as).image}"

                            column = @CONSUME(identifier).image

                            statement += " #{column}"
                }
                {
                    ALT : () =>
                        statement = @CONSUME(star).image
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
                            result += " #{@CONSUME(binaryOperator).image}"
                    }
                    {
                        ALT : () =>
                            result += " #{@CONSUME(unaryBinaryOperator).image}"
                    }
                ]

                result += " #{@SUBRULE2 @expr}"

            return result

        @RULE 'expr', () =>
            result = ''

            @OR [
                {
                    ALT : () =>
                        result = "#{@CONSUME(unaryOperator).image}"
                        result += " #{@SUBRULE1 @expr}"
                }
                {
                    ALT : () =>
                        result = "#{@CONSUME(unaryBinaryOperator).image}"
                        result += " #{@SUBRULE2 @expr}"
                }
                {
                    ALT : () =>
                        result = @SUBRULE @literalValue
                }
                {
                    ALT : () =>
                        result = @CONSUME(identifier).image

                        @OPTION () =>
                            result += " #{@CONSUME1(lparen).image} "

                            values = []

                            @MANY_SEP 
                                SEP : comma
                                DEF : () =>
                                    values.push @SUBRULE1 @exprCore

                            result += values.join ', '

                            result += " #{@CONSUME1(rparen).image}"
                }
                {
                    ALT : () =>
                        result = "#{@CONSUME2(lparen).image} "

                        values = []

                        @AT_LEAST_ONE_SEP
                            SEP : comma
                            DEF : () =>
                                values.push @SUBRULE2 @exprCore

                        result += values.join ', '

                        result += " #{@CONSUME2(rparen).image}"
                }
            ]

            return result

        @RULE 'literalValue', () =>
            result = ''

            @OR [
                {
                    ALT : () =>
                        result = @CONSUME(numericLiteral).image
                }
                {
                    ALT : () =>
                        result = @CONSUME(stringLiteral).image
                }
                {
                    ALT : () =>
                        result = @CONSUME(nullLiteral).image
                }
            ]

            return result

        Chevrotain.Parser.performSelfAnalysis this

    parse : (input, @table = null) =>
        lex = @lexer.tokenize input

        console.log JSON.stringify lex

        @input = lex.tokens
        result = @selectCore()

        if @errors.length > 0
            throw @errors

        return result

module.exports = SingularSqlParser