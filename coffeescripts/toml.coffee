TOKENS =
  key: /^([^=]+?)\s*=/
  keyGroup: /^(\s)*\[([^\]]+)\]/
  whiteSpace: /^\s+/
  string: /^([^\"]+)"/
  number: /^(-?\d+(?:\.\d+)?)/
  boolean: /^(true|false)/
  date: /^(\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ)/
  arraySeparator: /^[\s\n]*,[\s\n]*/
  arrayTerminator: /^[\s\n]*\]/
  comment: /^\s*#[^\n]*/


ESCAPE_CHARS =
  "0": "\0"
  "t": "\t"
  "n": "\n"
  "r": "\r"
  "\"": "\""
  "\\": "\\"


class Parser
  constructor: (@chunk, @result = {}, @currentKey = null) ->

  parse: ->
    while @chunk
      @skipNonTokens()

      if TOKENS.keyGroup.test(@chunk)
        return new KeyGroupParser(@chunk, @result, null)
      else if TOKENS.key.test(@chunk)
        return new KeyParser(@chunk, @result, null)
      else if @chunk
        throw "Error parsing string: #{@chunk}"

    this

  skipNonTokens: ->
    while @chunk && @chunk.substr(0,1).match(/(\s|\n|#)/)
      @skipWhiteSpace() || @skipNewline() || @skipComment()


  skipWhiteSpace: ->
    if match = @chunk.match(TOKENS.whiteSpace)
      @discard(match)

  skipNewline: ->
    if @chunk.substr(0,1).match(/\n/)
      @chunk = @chunk.substr(1)
    
  skipComment: ->
    if match = @chunk.match(TOKENS.comment)
      @discard(match)

  newParser: ->
    new Parser(@chunk, @result)

  discard: (match) ->
    @chunk = @chunk.substr(match[0].length)


class KeyGroupParser extends Parser
  parse: ->
    if match = @chunk.match(TOKENS.keyGroup)
      @discard(match)
      @skipNewline()
      
      keys = match[2].split('.')
      result = @result
      while keys.length
        key = keys.shift()
        result[key] ||= {}
        result = result[key]

      nextGroupIndex = @chunk.indexOf("\n#{match[1] || ''}[")
      groupChunk = if nextGroupIndex == -1 then @chunk else @chunk.substr(0, nextGroupIndex)
      nestedParser = new Parser(groupChunk, result)

      while nestedParser.chunk
        nestedParser = nestedParser.parse()

      @chunk = @chunk.substr(groupChunk.length)
      return new Parser(@chunk, @result)
    else
      throw "Bad keygroup at #{@chunk}"
      

class KeyParser extends Parser
  parse: ->
    if @chunk.substr(0,1).match(/\S/) && match = @chunk.match(TOKENS.key)
      @discard(match)
      return new ValueParser(@chunk, @result, match[1])
    else
      @chunk = ""

    this


class ValueParser extends Parser
  parse: ->
    @skipWhiteSpace()

    if @chunk.substr(0,1) == '"'
      return new StringParser(@chunk.substr(1), @result, @currentKey).parse()
    else if @chunk.substr(0,1) == '['
      return new ArrayParser(@chunk.substr(1), @result, @currentKey).parse()
    else if TOKENS.date.test(@chunk)
      return new DateParser(@chunk, @result, @currentKey).parse()
    else if TOKENS.number.test(@chunk)
      return new NumberParser(@chunk, @result, @currentKey).parse()
    else if TOKENS.boolean.test(@chunk)
      return new BooleanParser(@chunk, @result, @currentKey).parse()
    else
      throw "Bad value at #{@chunk}"

    this


class ArrayParser extends Parser
  parse: ->
    @result[@currentKey] = []

    @skipNonTokens()

    while @chunk
      parser = new ValueParser(@chunk, {}, 'value')
      parser = parser.parse()

      @result[@currentKey].push(parser.result.value)
      @chunk = parser.chunk

      @skipNonTokens()

      if match = @chunk.match(TOKENS.arraySeparator)
        @discard(match)
        @skipNonTokens()

      if match = @chunk.match(TOKENS.arrayTerminator)
        @discard(match)
        return @newParser()

    this


class PrimitiveParser extends Parser
  parse: ->
    if match = @chunk.match(@regexp)
      @result[@currentKey] = @cast(match[1])
      @discard(match)
    else
      throw "Bad value #{@chunk}"

    @newParser()

  cast: (val) -> val


class StringParser extends Parser
  parse: ->
    @result[@currentKey] = ''
    string = []
    while @chunk.length
      if @chunk.substr(0,1) == '"'
        @chunk = @chunk.substr(1)
        @result[@currentKey] = string.join('')
        return @newParser()

      if @chunk.substr(0,1) == '\\'
        char = ESCAPE_CHARS[@chunk.substr(1,1)]
        string.push(if char then char else "\\#{@chunk.substr(1,1)}")
        @chunk = @chunk.substr(2)

      nextSlash = @chunk.indexOf('\\')
      nextQuote = @chunk.indexOf('"')
      next = if nextSlash == -1 then nextQuote else Math.min(nextSlash, nextQuote)  

      throw "Unterminated string literal: #{@chunk}" if nextQuote == -1

      string.push(@chunk.substr(0, next))
      @chunk = @chunk.substr(next)

    this


class DateParser extends PrimitiveParser
  regexp: TOKENS.date
  cast: (val) -> new Date(Date.parse(val))


class NumberParser extends PrimitiveParser
  regexp: TOKENS.number
  cast: parseFloat


class BooleanParser extends PrimitiveParser
  regexp: TOKENS.boolean
  cast: (val) -> val == "true"


TOML =
  parse: (string) ->
    parser = new Parser(string)
    while parser.chunk
      parser = parser.parse()

    return parser.result

if window?
  window.TOML = TOML
else
  exports.TOML = TOML