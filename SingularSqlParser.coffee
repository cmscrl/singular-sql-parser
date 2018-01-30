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
            pattern : /\|\||\*|\/|%|\+|-|<<|>>|&|\||<|<=|>|>=|=|==|\!=|<>|(is|is not|in|like|glob|match|regexp|and|or)(?!\w)/i

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
            pattern : /\d+(?!\w)/

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
        
        unaryOperator = Chevrotain.createToken
            name : 'unaryOperator'
            pattern : /-|\+|~|not(?!\w)/i

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
            result = "#{@CONSUME(select).image} "

            @OPTION1 () =>
                @OR [
                    {
                        ALT : () =>
                            result += "#{@CONSUME(all).image} "
                    }
                    {
                        ALT : () =>
                            result += "#{@CONSUME(distinct).image} "
                    }
                ]

            values = []

            @AT_LEAST_ONE_SEP1
                SEP : comma,
                DEF : () =>
                    values.push @SUBRULE @resultColumn

            result += values.join ', '

            if @table?
                result += " FROM #{@table}"

            @OPTION2 () =>
                result += " #{@CONSUME(where).image}"
                result += " #{@SUBRULE1 @exprCore}"

            @OPTION3 () =>
                result += " #{@CONSUME(groupby).image} "

                values = []

                @AT_LEAST_ONE_SEP2
                    SEP : comma,
                    DEF : () =>
                        values.push @SUBRULE2 @exprCore

                result += values.join ', '

                @OPTION4 () =>
                    result += " #{@CONSUME(having).image}"
                    result += " #{@SUBRULE3 @exprCore}"

            return result

        @RULE 'resultColumn', () =>
            result = ''

            @OR [
                {
                    ALT : () =>
                        result = @SUBRULE @exprCore

                        @OPTION () =>
                            result += " #{@CONSUME(as).image}"
                            result += " #{@CONSUME(identifier).image}"
                }
                {
                    ALT : () =>
                        result = @CONSUME(star).image
                }
            ]

            return result

        @RULE 'exprCore', () =>
            result = ''

            @OPTION1 () =>
                result = "#{@CONSUME(unaryOperator).image} "

            result += @SUBRULE @expr

            @OPTION2 () =>
                @OR [
                    {
                        ALT : () =>
                            result += " #{@CONSUME(binaryOperator).image}"
                            result += " #{@SUBRULE @exprCore}"
                    }
                    {
                        ALT : () =>
                            result += " #{@CONSUME(suffixOperator).image}"
                    }
                ]

            return result

        @RULE 'expr', () =>
            result = ''

            @OR [
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

        @input = lex.tokens
        result = @selectCore()

        if @errors.length > 0
            throw @errors

        return result

module.exports = SingularSqlParser