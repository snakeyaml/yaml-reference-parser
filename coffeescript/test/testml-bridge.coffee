require '../../test/testml/src/coffee/lib/testml/bridge'
require '../lib/prelude'
require '../lib/parser'
require '../lib/grammar'
require '../lib/test-receiver'

module.exports =
class TestMLBridge extends TestML.Bridge

  parse: (yaml, expect_error=null)->
    parser = new Parser(new TestReceiver)

    error = ''
    try
      parser.parse yaml
    catch e
      error = String e

    if expect_error?
      return if error then 1 else 0

    if error
      error
    else
      parser.receiver.output

  unescape: (text)->
    text = text
      .replace(/␣/g, ' ')
      .replace(/—*»/g, "\t")
      .replace(/⇔/g, "\uFEFF")
      .replace(/↵/g, '')
      .replace(/∎\n$/, '')

    # text = text.replace(/↓/g, "\r")

    return text

  fix_test_output: (text)->
    return text
