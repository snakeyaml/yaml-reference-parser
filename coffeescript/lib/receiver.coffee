require './prelude'

stream_start_event = ->
  event: 'stream_start'
stream_end_event = ->
  event: 'stream_end'
document_start_event = (explicit=false)->
  event: 'document_start'
  explicit: explicit
  version: null
document_end_event = (explicit=false)->
  event: 'document_end'
  explicit: explicit
mapping_start_event = (flow=false)->
  event: 'mapping_start'
  flow: flow
mapping_end_event = ->
  event: 'mapping_end'
sequence_start_event = (flow=false)->
  event: 'sequence_start'
  flow: flow
sequence_end_event = ->
  event: 'sequence_end'
scalar_event = (style, value)->
  event: 'scalar'
  style: style
  value: value
alias_event = (name)->
  event: 'alias'
  name: name
cache = (text)->
  text: text

global.Receiver = class Receiver
  constructor: ->
    @event = []
    @cache = []

  send: (event)->
    if @callback
      @callback event
    else
      @event.push event

  add: (event)->
    if event.event?
      if @anchor?
        event.anchor = @anchor
        delete @anchor
      if @tag?
        event.tag = @tag
        delete @tag
    @push event
    return event


  push: (event)->
    if @cache.length
      _.last(@cache).push event
    else
      if event.event.match /(mapping_start|sequence_start|scalar)/
        @check_document_start()
      @send event

  cache_up: (event=null)->
    @cache.push []
    @add event if event?

  cache_down: (event=null)->
    events = @cache.pop() or FAIL 'cache_down'
    @push e for e in events
    @add event if event?

  cache_drop: ->
    events = @cache.pop() or FAIL 'cache_drop'
    return events

  cache_get: (type)->
    last = _.last @cache
    return \
      last &&
      last[0] &&
      last[0].event == type &&
      last[0]

  check_document_start: ->
    return unless @document_start
    @send @document_start
    delete @document_start
    @document_end = document_end_event()

  check_document_end: ->
    return unless @document_end
    @send @document_end
    delete @document_end
    @tag_map = {}
    @document_start = document_start_event()

  #----------------------------------------------------------------------------
  try__yaml_stream: ->
    @add stream_start_event()
    @tag_map = {}
    @document_start = document_start_event()
    delete @document_end
  got__yaml_stream: ->
    @check_document_end()
    @add stream_end_event()

  got__yaml_version_number: (o)->
    die "Multiple %YAML directives not allowed" \
      if @document_start.version?
    @document_start.version = o.text

  got__tag_handle: (o)->
    @tag_handle = o.text
  got__tag_prefix: (o)->
    @tag_map[@tag_handle] = o.text

  got__document_start_indicator: ->
    @check_document_end()
    @document_start.explicit = true

  got__document_end_indicator: ->
    if @document_end?
      @document_end.explicit = true
    @check_document_end()

  got__flow_mapping__all__x7b: -> @add mapping_start_event true
  got__flow_mapping__all__x7d: -> @add mapping_end_event()

  got__flow_sequence__all__x5b: -> @add sequence_start_event true
  got__flow_sequence__all__x5d: -> @add sequence_end_event()

  try__block_mapping: -> @cache_up mapping_start_event()
  got__block_mapping: -> @cache_down mapping_end_event()
  not__block_mapping: -> @cache_drop()

  try__block_sequence_context: -> @cache_up sequence_start_event()
  got__block_sequence_context: -> @cache_down sequence_end_event()
  not__block_sequence_context: ->
    event = @cache_drop()[0]
    @anchor = event.anchor
    @tag = event.tag

  try__compact_mapping: -> @cache_up mapping_start_event()
  got__compact_mapping: -> @cache_down mapping_end_event()
  not__compact_mapping: -> @cache_drop()

  try__compact_sequence: -> @cache_up sequence_start_event()
  got__compact_sequence: -> @cache_down sequence_end_event()
  not__compact_sequence: -> @cache_drop()

  try__flow_pair: -> @cache_up mapping_start_event true
  got__flow_pair: -> @cache_down mapping_end_event()
  not__flow_pair: -> @cache_drop()

  try__block_mapping_implicit_entry: -> @cache_up()
  got__block_mapping_implicit_entry: -> @cache_down()
  not__block_mapping_implicit_entry: -> @cache_drop()

  try__block_mapping_explicit_entry: -> @cache_up()
  got__block_mapping_explicit_entry: -> @cache_down()
  not__block_mapping_explicit_entry: -> @cache_drop()

  try__flow_mapping_empty_key_entry: -> @cache_up()
  got__flow_mapping_empty_key_entry: -> @cache_down()
  not__flow_mapping_empty_key_entry: -> @cache_drop()

  got__flow_plain_scalar: (o)->
    text = o.text
      .replace(/(?:[\ \t]*\r?\n[\ \t]*)/g, "\n")
      .replace(/(\n)(\n*)/g, (m...)-> if m[2].length then m[2] else ' ')
    @add scalar_event 'plain', text

  got__single_quoted_scalar: (o)->
    text = o.text[1...-1]
      .replace(/(?:[\ \t]*\r?\n[\ \t]*)/g, "\n")
      .replace(/(\n)(\n*)/g, (m...)-> if m[2].length then m[2] else ' ')
      .replace(/''/g, "'")
    @add scalar_event 'single', text

  got__double_quoted_scalar: (o)->
    text = o.text[1...-1]
      .replace(/(?<!\\)(?:[\ \t]*\r?\n[\ \t]*)/g, "\n")
      .replace(/\\\n[\ \t]*/g, '')
      .replace(/(\n)(\n*)/g, (m...)-> if m[2].length then m[2] else ' ')
      .replace(/\\(["\/])/g, "$1")
      .replace(/\\ /g, ' ')
      .replace(/\\b/g, "\b")
      .replace(/\\\t/g, "\t")
      .replace(/\\t/g, "\t")
      .replace(/\\n/g, "\n")
      .replace(/\\r/g, "\r")
      .replace /\\x([0-9a-fA-F]{2})/g, (m...)->
        String.fromCharCode(parseInt(m[1], 16))
      .replace /\\u([0-9a-fA-F]{4})/g, (m...)->
        String.fromCharCode(parseInt(m[1], 16))
      .replace /\\U([0-9a-fA-F]{8})/g, (m...)->
        String.fromCharCode(parseInt(m[1], 16))
      .replace(/\\\\/g, '\\')

    @add scalar_event 'double', text

  got__empty_line: ->
    @add cache('') if @in_scalar
  got__literal_scalar_line_content__all__all: (o)->
    @add cache(o.text)
  try__block_literal_scalar: ->
    @in_scalar = true
    @cache_up()
  got__block_literal_scalar: ->
    delete @in_scalar
    lines = @cache_drop()
    lines.pop() if lines.length > 0 and lines[lines.length - 1].text == ''
    lines = lines.map (l)-> "#{l.text}\n"
    text = lines.join ''
    t = @parser.state_curr().t
    if t == 'CLIP'
      text = text.replace /\n+$/, "\n"
    else if t == 'STRIP'
      text = text.replace /\n+$/, ""
    @add scalar_event 'literal', text
  not__block_literal_scalar: ->
    delete @in_scalar
    @cache_drop()

  got__folded_scalar_text__all__all__rgx: (o)->
    @add cache o.text
  got__folded_scalar_spaced_text__all__all: (o)->
    @add cache o.text
  try__block_folded_scalar: ->
    @in_scalar = true
    @cache_up()
  got__block_folded_scalar: ->
    delete @in_scalar
    lines = @cache_drop().map (l)-> l.text
    text = lines.join "\n"
    text = text.replace /^(\S.*)\n(?=\S)/gm, "$1 "
    text = text.replace /^(\S.*)\n(\n+)/gm, "$1$2"
    text = text.replace /^([\ \t]+\S.*)\n(\n+)(?=\S)/gm, "$1$2"
    text += "\n"

    t = @parser.state_curr().t
    if t == 'CLIP'
      text = text.replace /\n+$/, "\n"
      text = '' if text == "\n"
    else if t == 'STRIP'
      text = text.replace /\n+$/, ""
    @add scalar_event 'folded', text
  not__block_folded_scalar: ->
    delete @in_scalar
    @cache_drop()

  got__empty_node: -> @add scalar_event 'plain', ''

  not__block_collection__all__rep__all__any__all: ->
    delete @tag
    delete @anchor

  got__anchor_property: (o)->
    @anchor = o.text[1..]

  got__tag_property: (o)->
    tag = o.text
    if m = tag.match /^!<(.*)>$/
      @tag = m[1]
    else if m = tag.match /^!!(.*)/
      prefix = @tag_map['!!']
      if prefix?
        @tag = prefix + tag[2..]
      else
        @tag = "tag:yaml.org,2002:#{m[1]}"
    else if m = tag.match(/^(!.*?!)/)
      prefix = @tag_map[m[1]]
      if prefix?
        @tag = prefix + tag[(m[1].length)..]
      else
        die "No %TAG entry for '#{prefix}'"
    else if (prefix = @tag_map['!'])?
      @tag = prefix + tag[1..]
    else
      @tag = tag
    @tag = @tag.replace /%([0-9a-fA-F]{2})/g, (m...)->
      String.fromCharCode parseInt m[1], 16

  got__alias_node: (o)-> @add alias_event o.text[1..]

# vim: sw=2:
