global.Grammar = class Grammar

  # Helper functions:

  # Generate required regular expression and string variants:
  r = (rgx)->
    str = String(rgx)
    if str.match(/undefined/)
      die (new Error "Bad regex '#{rgx}'").stack
    str = str[0..-2] if str.endsWith('u')
    str = String(str)[1..-2]
    chars = str[1..-2]
    regexp = /// #{str} ///yum
    return [ str, regexp, chars ]

  start_of_line = '^'
  end_of_file = '$'


  # Grammar rules:

  TOP: -> @yaml_stream



  # [001]
  # yaml-stream ::=
  #   document-prefix*
  #   any-document?
  #   (
  #       (
  #         document-suffix+
  #         document-prefix*
  #         any-document?
  #       )
  #     | byte-order-mark
  #     | comment-line
  #     | start-indicator-and-document
  #   )*

  yaml_stream: ->
    @all(
      @document_prefix
      @rep(0, 1, @any_document)
      @rep(0, null,
        @any(
          @all(
            @document_suffix
            @rep(0, null, @document_prefix)
            @rep(0, 1, @any_document)
          )
          @all(
            @document_prefix
            @rep(0, 1, @start_indicator_and_document)
          )
        )
      )
    )



  # [002]
  # document-prefix ::=
  #   byte-order-mark?
  #   comment-line*

  document_prefix: ->
    @all(
      @rep(0, 1, @chr(byte_order_mark))
      @rep(0, null, @l_comment)
    )



  # [003]
  # document-suffix ::=
  #   document-end-indicator
  #   comment-lines

  document_suffix: ->
    @all(
      @document_end_indicator
      @comment_lines
    )



  # [004]
  # document-start-indicator ::=
  #   "---"

  [document_start_indicator, re_document_start_indicator] = []

  i004 = ->
    [document_start_indicator, re_document_start_indicator] = r ///
      ---
      #{ws_lookahead}
    ///

  document_start_indicator: ->
    @rgx(re_document_start_indicator)



  # [005]
  # document-end-indicator ::=
  #   "..."                             # Not followed by non-ws char

  [document_end_indicator, re_document_end_indicator] = r ///
    \.\.\.
  ///

  document_end_indicator: ->
    @rgx(re_document_end_indicator)



  # [006]
  # any-document ::=
  #     directives-and-document
  #   | start-indicator-and-document
  #   | bare-document

  any_document: ->
    @any(
      @directives_and_document
      @start_indicator_and_document
      @bare_document
    )



  # [007]
  # directives-and-document ::=
  #   directive-line+
  #   start-indicator-and-document

  directives_and_document: ->
    @all(
      @rep(1, null, @directive_line)
      @start_indicator_and_document
    )



  # [008]
  # start-indicator-and-document ::=
  #   document-start-indicator
  #   (
  #       bare-document
  #     | (
  #         empty-node
  #         comment-lines
  #       )
  #   )

  start_indicator_and_document: ->
    @all(
      @document_start_indicator
      @any(
        @bare_document
        @all(
          @empty_node
          @comment_lines
        )
      )
    )



  # [009]
  # bare-document ::=
  #   block-node(-1,BLOCK-IN)
  #   /* Excluding forbidden-content */

  bare_document: ->
    @all(
      @exclude(@forbidden_content)
      [ @block_node, -1, "block-in" ]
    )



  # [010]
  # directive-line ::=
  #   '%'
  #   (
  #       yaml-directive-line
  #     | tag-directive-line
  #     | reserved-directive-line
  #   )
  #   comment-lines

  directive_line: ->
    @all(
      @chr('%')
      @any(
        @yaml_directive_line
        @tag_directive_line
        @reserved_directive_line
      )
      @comment_lines
    )



  # [011]
  # forbidden-content ::=
  #   <start-of-line>
  #   (
  #       document-start-indicator
  #     | document-end-indicator
  #   )
  #   (
  #       line-ending
  #     | blank-character
  #   )

  forbidden_content: ->
    @rgx(
      ///
        (?:
          #{start_of_line}
          (?:
            #{document_start_indicator}
          | #{document_end_indicator}
          )
          (?:   # XXX slightly different than 1.3 spec
            [
              \x0A
              \x0D
            ]
          | #{blank_character}
          | #{end_of_file}
          )
        )
      ///y
    )



  # [012]
  # block-node(n,c) ::=
  #     block-node-in-a-block-node(n,c)
  #   | flow-node-in-a-block-node(n)

  block_node: (n, c)->
    @any(
      [ @block_node_in_a_block_node, n, c ]
      [ @flow_node_in_a_block_node, n ]
    )



  # [013]
  # block-node-in-a-block-node(n,c) ::=
  #     block-scalar(n,c)
  #   | block-collection(n,c)

  block_node_in_a_block_node: (n, c)->
    @any(
      [ @block_scalar, n, c ]
      [ @block_collection, n, c ]
    )



  # [014]
  # flow-node-in-a-block-node(n) ::=
  #   separation-characters(n+1,FLOW-OUT)
  #   flow-node(n+1,FLOW-OUT)
  #   comment-lines

  flow_node_in_a_block_node: (n)->
    @all(
      [ @separation_characters, n + 1, "flow-out" ]
      [ @flow_node, n + 1, "flow-out" ]
      @comment_lines
    )



  # [015]
  # block-collection(n,c) ::=
  #   (
  #     separation-characters(n+1,c)
  #     node-properties(n+1,c)
  #   )?
  #   comment-lines
  #   (
  #       block-sequence-context(n,c)
  #     | block-mapping(n)
  #   )

  block_collection: (n, c)->
    @all(
      @rep(0, 1,
        @all(
          [ @separation_characters, n + 1, c ]
          @any(
            @all(
              [ @node_properties, n + 1, c ]
              @comment_lines
            )

            # XXX Needed by receiver to get only a tag or anchor:
            @all(
              @tag_property
              @comment_lines
            )
            @all(
              @anchor_property
              @comment_lines
            )
          )
        )
      )
      @comment_lines
      @any(
        [ @block_sequence_context, n, c ]
        [ @block_mapping, n ]
      )
    )



  # [016]
  # block-sequence-context(n,BLOCK-OUT) ::= block-sequence(n-1)
  # block-sequence-context(n,BLOCK-IN)  ::= block-sequence(n)

  block_sequence_context: (n, c)->
    @case c,
      'block-out': [ @block_sequence, @sub(n, 1) ]
      'block-in':  [ @block_sequence, n ]



  # [017]
  # block-scalar(n,c) ::=
  #   separation-characters(n+1,c)
  #   (
  #     node-properties(n+1,c)
  #     separation-characters(n+1,c)
  #   )?
  #   (
  #       block-literal-scalar(n)
  #     | block-folded-scalar(n)
  #   )

  block_scalar: (n, c)->
    @all(
      [ @separation_characters, n + 1, c ]
      @rep(0, 1,
        @all(
          [ @node_properties, n + 1, c ]
          [ @separation_characters, n + 1, c ]
        )
      )
      @any(
        [ @block_literal_scalar, n ]
        [ @block_folded_scalar, n ]
      )
    )



  # [018]
  # block-mapping(n) ::=
  #   (
  #     indentation-spaces(n+1+m)
  #     block-mapping-entry(n+1+m)
  #   )+

  block_mapping: (n)->
    return false unless m = @call [@auto_detect_indent, n], 'number'
    @all(
      @rep(1, null,
        @all(
          @indentation_spaces_n(n + m)
          [ @block_mapping_entry, n + m ]
        )
      )
    )



  # [019]
  # block-mapping-entry(n) ::=
  #     block-mapping-explicit-entry(n)
  #   | block-mapping-implicit-entry(n)

  block_mapping_entry: (n)->
    @any(
      [ @block_mapping_explicit_entry, n ]
      [ @block_mapping_implicit_entry, n ]
    )



  # [020]
  # block-mapping-explicit-entry(n) ::=
  #   block-mapping-explicit-key(n)
  #   (
  #       block-mapping-explicit-value(n)
  #     | empty-node
  #   )

  block_mapping_explicit_entry: (n)->
    @all(
      [ @block_mapping_explicit_key, n ]
      @any(
        [ @block_mapping_explicit_value, n ]
        @empty_node
      )
    )



  # [021]
  # block-mapping-explicit-key(n) ::=
  #   '?'                               # Not followed by non-ws char
  #   block-indented-node(n,BLOCK-OUT)

  block_mapping_explicit_key: (n)->
    @all(
      @rgx(///
        \?
        #{ws_lookahead}
      ///y)
      [ @block_indented_node, n, "block-out" ]
    )



  # [022]
  # block-mapping-explicit-value(n) ::=
  #   indentation-spaces(n)
  #   ':'                               # Not followed by non-ws char
  #   block-indented-node(n,BLOCK-OUT)

  block_mapping_explicit_value: (n)->
    @all(
      @indentation_spaces_n(n)
      @rgx(///
        :
        #{ws_lookahead}
      ///y)
      [ @block_indented_node, n, "block-out" ]
    )



  # [023]
  # block-mapping-implicit-entry(n) ::=
  #   (
  #       block-mapping-implicit-key
  #     | empty-node
  #   )
  #   block-mapping-implicit-value(n)

  block_mapping_implicit_entry: (n)->
    @all(
      @any(
        @block_mapping_implicit_key
        @empty_node
      )
      [ @block_mapping_implicit_value, n ]
    )



  # XXX Can fold into 023
  # [024]
  # block-mapping-implicit-key ::=
  #     implicit-json-key(BLOCK-KEY)
  #   | implicit-yaml-key(BLOCK-KEY)

  block_mapping_implicit_key: ->
    @any(
      [ @implicit_json_key, "block-key" ],
      [ @implicit_yaml_key, "block-key" ]
    )



  # [025]
  # block-mapping-implicit-value(n) ::=
  #   ':'                               # Not followed by non-ws char
  #   (
  #       block-node(n,BLOCK-OUT)
  #     | (
  #         empty-node
  #         comment-lines
  #       )
  #   )

  block_mapping_implicit_value: (n)->
    @all(
      @rgx(///
        :
        #{ws_lookahead}
      ///y)
      @any(
        [ @block_node, n, "block-out" ]
        @all(
          @empty_node
          @comment_lines
        )
      )
    )



  # [026]
  # compact-mapping(n) ::=
  #   block-mapping-entry(n)
  #   (
  #     indentation-spaces(n)
  #     block-mapping-entry(n)
  #   )*

  compact_mapping: (n)->
    @all(
      [ @block_mapping_entry, n ]
      @rep(0, null,
        @all(
          @indentation_spaces_n(n)
          [ @block_mapping_entry, n ]
        )
      )
    )



  # [027]
  # block-sequence(n) ::=
  #   (
  #     indentation-spaces(n+1+m)
  #     block-sequence-entry(n+1+m)
  #   )+

  block_sequence: (n)->
    return false unless m = @call [@auto_detect_indent, n], 'number'
    @all(
      @rep(1, null,
        @all(
          @indentation_spaces_n(n + m)
          [ @block_sequence_entry, n + m ]
        )
      )
    )



  # [028]
  # block-sequence-entry(n) ::=
  #   '-'
  #   [ lookahead ≠ non-space-character ]
  #   block-indented-node(n,BLOCK-IN)

  block_sequence_entry: (n)->
    @all(
      @rgx(///
        -
        #{ws_lookahead}
        (?! #{non_space_character} )
      ///yu)
      [ @block_indented_node, n, "block-in" ]
    )



  # [029]
  # block-indented-node(n,c) ::=
  #     (
  #       indentation-spaces(m)
  #       (
  #           compact-sequence(n+1+m)
  #         | compact-mapping(n+1+m)
  #       )
  #     )
  #   | block-node(n,c)
  #   | (
  #       empty-node
  #       comment-lines
  #     )

  block_indented_node: (n, c)->
    m = @call [@auto_detect_indent, n], 'number'
    @any(
      @all(
        @indentation_spaces_n(m)
        @any(
          [ @compact_sequence, n + 1 + m ]
          [ @compact_mapping, n + 1 + m ]
        )
      )
      [ @block_node, n, c ]
      @all(
        @empty_node
        @comment_lines
      )
    )



  # [030]
  # compact-sequence(n) ::=
  #   block-sequence-entry(n)
  #   (
  #     indentation-spaces(n)
  #     block-sequence-entry(n)
  #   )*

  compact_sequence: (n)->
    @all(
      [ @block_sequence_entry, n ]
      @rep(0, null,
        @all(
          @indentation_spaces_n(n)
          [ @block_sequence_entry, n ]
        )
      )
    )



  # [031]
  # block-literal-scalar(n) ::=
  #   '|'
  #   block-scalar-indicators(t)
  #   literal-scalar-content(n+m,t)

  block_literal_scalar: (n)->
    @all(
      @chr('|')
      [ @block_scalar_indicator, n ]
      [ @literal_scalar_content, @add(n, @m()), @t() ]
    )



  # [032]
  # literal-scalar-content(n,t) ::=
  #   (
  #     literal-scalar-line-content(n)
  #     literal-scalar-next-line(n)*
  #     block-scalar-chomp-last(t)
  #   )?
  #   block-scalar-chomp-empty(n,t)

  literal_scalar_content: (n, t)->
    @all(
      @rep(0, 1,
        @all(
          [ @literal_scalar_line_content, n ]
          @rep(0, null, [ @literal_scalar_next_line, n ])
          [ @block_scalar_chomp_last, t ]
        )
      )
      [ @block_scalar_chomp_empty, n, t ]
    )



  # [033]
  # literal-scalar-line-content(n) ::=
  #   empty-line(n,BLOCK-IN)*
  #   indentation-spaces(n)
  #   non-break-character+

  literal_scalar_line_content: (n)->
    @all(
      @rep(0, null, [ @empty_line, n, "block-in" ])
      @indentation_spaces_n(n)
      # XXX @all used to disambiguate @rgx capture:
      @all(
        @rgx(/// #{non_break_character}+ ///yu)
      )
    )



  # [034]
  # literal-scalar-next-line(n) ::=
  #   break-as-line-feed
  #   literal-scalar-line-content(n)

  literal_scalar_next_line: (n)->
    @all(
      @rgx(re_break_as_line_feed)
      [ @literal_scalar_line_content, n ]
    )



  # [035]
  # block-folded-scalar(n) ::=
  #   '>'
  #   block-scalar-indicators(t)
  #   folded-scalar-content(n+m,t)

  block_folded_scalar: (n)->
    @all(
      @chr('>')
      [ @block_scalar_indicator, n ]
      [ @folded_scalar_content, @add(n, @m()), @t() ]
    )



  # [036]
  # folded-scalar-content(n,t) ::=
  #   (
  #     folded-scalar-lines-different-indentation(n)
  #     block-scalar-chomp-last(t)
  #   )?
  #   block-scalar-chomp-empty(n,t)

  folded_scalar_content: (n, t)->
    @all(
      @rep(0, 1,
        @all(
          [ @folded_scalar_lines_different_indentation, n ]
          [ @block_scalar_chomp_last, t ]
        )
      )
      [ @block_scalar_chomp_empty, n, t ]
    )



  # [037]
  # folded-scalar-lines-different-indentation(n) ::=
  #   folded-scalar-lines-same-indentation(n)
  #   (
  #     break-as-line-feed
  #     folded-scalar-lines-same-indentation(n)
  #   )*

  folded_scalar_lines_different_indentation: (n)->
    @all(
      [ @folded_scalar_lines_same_indentation, n ]
      @rep(0, null,
        @all(
          @rgx(re_break_as_line_feed)
          [ @folded_scalar_lines_same_indentation, n ]
        )
      )
    )



  # [038]
  # folded-scalar-lines-same-indentation(n) ::=
  #   empty-line(n,BLOCK-IN)*
  #   (
  #       folded-scalar-lines(n)
  #     | folded-scalar-spaced-lines(n)
  #   )

  folded_scalar_lines_same_indentation: (n)->
    @all(
      @rep(0, null, [ @empty_line, n, "block-in" ])
      @any(
        [ @folded_scalar_lines, n ]
        [ @folded_scalar_spaced_lines, n ]
      )
    )



  # [039]
  # folded-scalar-lines(n) ::=
  #   folded-scalar-text(n)
  #   (
  #     folded-whitespace(n,BLOCK-IN)
  #     folded-scalar-text(n)
  #   )*

  folded_scalar_lines: (n)->
    @all(
      [ @folded_scalar_text, n ]
      @rep(0, null,
        @all(
          [ @folded_whitespace, n, "block-in" ]
          [ @folded_scalar_text, n ]
        )
      )
    )



  # [040]
  # folded-scalar-spaced-lines(n) ::=
  #   folded-scalar-spaced-text(n)
  #   (
  #     line-break-and-empty-lines(n)
  #     folded-scalar-spaced-text(n)
  #   )*

  folded_scalar_spaced_lines: (n)->
    @all(
      [ @folded_scalar_spaced_text, n ]
      @rep(0, null,
        @all(
          [ @line_break_and_empty_lines, n ]
          [ @folded_scalar_spaced_text, n ]
        )
      )
    )



  # [041]
  # folded-scalar-text(n) ::=
  #   indentation-spaces(n)
  #   non-space-character
  #   non-break-character*

  folded_scalar_text: (n)->
    @all(
      @indentation_spaces_n(n)
      # XXX @all used to disambiguate @rgx capture:
      @all(
        @rgx(///
          #{non_space_character}+
          #{non_break_character}*
        ///yu)
      )
    )



  # [042]
  # line-break-and-empty-lines(n) ::=
  #   break-as-line-feed
  #   empty-line(n,BLOCK-IN)*

  line_break_and_empty_lines: (n)->
    @all(
      @rgx(re_break_as_line_feed)
      @rep(0, null, [ @empty_line, n, "block-in" ])
    )



  # [043]
  # folded-scalar-spaced-text(n) ::=
  #   indentation-spaces(n)
  #   blank-character
  #   non-break-character*

  folded_scalar_spaced_text: (n)->
    @all(
      @indentation_spaces_n(n)
      @all(
        @rgx(///
          #{blank_character}
          #{non_break_character}*
        ///yu)
      )
    )



  # [044]
  # block-scalar-indicators(t) ::=
  #   (
  #       (
  #         block-scalar-indentation-indicator
  #         block-scalar-chomping-indicator(t)
  #       )
  #     | (
  #         block-scalar-chomping-indicator(t)
  #         block-scalar-indentation-indicator
  #       )
  #   )
  #   (
  #       comment-line
  #     | line-ending
  #   )

  block_scalar_indicator: (n)->
    @all(
      @any(
        @all(
          [ @block_scalar_indentation_indicator, n ]
          @block_scalar_chomping_indicator
          @rgx(ws_lookahead)
        )
        @all(
          @block_scalar_chomping_indicator
          [ @block_scalar_indentation_indicator, n ]
          @rgx(ws_lookahead)
        )
      )
      @comment_line
    )



  # [045]
  # block-scalar-indentation-indicator ::=
  #   decimal-digit-1-9

  block_scalar_indentation_indicator: (n)->
    @any(
      @if(@rgx(re_decimal_digit_1_9), @set('m', @ord(@match)))
      @if(@empty, @set('m', [ @auto_detect, n ]))
    )



  # [046]
  # block-scalar-chomping-indicator(STRIP) ::= '-'
  # block-scalar-chomping-indicator(KEEP)  ::= '+'
  # block-scalar-chomping-indicator(CLIP)  ::= ""

  block_scalar_chomping_indicator: ->
    @any(
      @if(@chr('-'), @set('t', "strip"))
      @if(@chr('+'), @set('t', "keep"))
      @if(@empty, @set('t', "clip"))
    )



  # [047]
  # block-scalar-chomp-last(STRIP) ::= line-break | <end-of-input>
  # block-scalar-chomp-last(CLIP)  ::= break-as-line-feed | <end-of-input>
  # block-scalar-chomp-last(KEEP)  ::= break-as-line-feed | <end-of-input>

  block_scalar_chomp_last: (t)->
    @case t,
      'clip': @any( @rgx(re_break_as_line_feed), @end_of_stream )
      'keep': @any( @rgx(re_break_as_line_feed), @end_of_stream )
      'strip': @any( @rgx(re_line_break), @end_of_stream )



  #   [048]
  #   block-scalar-chomp-empty(n,STRIP) ::= line-strip-empty(n)
  #   block-scalar-chomp-empty(n,CLIP)  ::= line-strip-empty(n)
  #   block-scalar-chomp-empty(n,KEEP)  ::= line-keep-empty(n)

  block_scalar_chomp_empty: (n, t)->
    @case t,
      'strip': [ @line_strip_empty, n ]
      'clip': [ @line_strip_empty, n ]
      'keep': [ @line_keep_empty, n ]



  # [049]
  # line-strip-empty(n) ::=
  #   (
  #     indentation-spaces-less-or-equal(n)
  #     line-break
  #   )*
  #   line-trail-comments(n)?

  line_strip_empty: (n)->
    @all(
      @rep(0, null,
        @all(
          [ @indentation_spaces_less_or_equal, n ]
          @rgx(re_line_break)
        )
      )
      @rep(0, 1, [ @line_trail_comments, n ])
    )



  # [050]
  # line-keep-empty(n) ::=
  #   empty-line(n,BLOCK-IN)*
  #   line-trail-comments(n)?

  line_keep_empty: (n)->
    @all(
      @rep(0, null, [ @empty_line, n, "block-in" ])
      @rep(0, 1, [ @line_trail_comments, n ])
    )



  # [051]
  # line-trail-comments(n) ::=
  #   indentation-spaces-less-than(n)
  #   comment-content
  #   line-ending
  #   comment-line*

  re_line_trail_comments = ''

  i051 = ->
    [, re_line_trail_comments] = r ///
      #{comment_content}
      #{line_ending}
    ///u

  line_trail_comments: (n)->
    @all(
      [ @indentation_spaces_less_than, n ]
      @rgx(re_line_trail_comments)
      @rep(0, null, @l_comment)
    )



  # [052]
  # flow-node(n,c) ::=
  #     alias-node
  #   | flow-content(n,c)
  #   | (
  #       node-properties(n,c)
  #       (
  #         (
  #           separation-characters(n,c)
  #           flow-content(n,c)
  #         )
  #         | empty-node
  #       )
  #     )

  flow_node: (n, c)->
    @any(
      @alias_node
      [ @flow_content, n, c ]
      @all(
        [ @node_properties, n, c ]
        @any(
          @all(
            [ @separation_characters, n, c ]
            [ @flow_content, n, c ]
          )
          @empty_node
        )
      )
    )



  # [053]
  # flow-content(n,c) ::=
  #     flow-yaml-content(n,c)
  #   | flow-json-content(n,c)

  flow_content: (n, c)->
    @any(
      [ @flow_yaml_content, n, c ]
      [ @flow_json_content, n, c ]
    )



  # [054]
  # flow-yaml-content(n,c) ::=
  #   flow-plain-scalar(n,c)

  flow_yaml_content: (n, c)->
    [ @flow_plain_scalar, n, c ]



  # [055]
  # flow-json-content(n,c) ::=
  #     flow-sequence(n,c)
  #   | flow-mapping(n,c)
  #   | single-quoted-scalar(n,c)
  #   | double-quoted-scalar(n,c)

  flow_json_content: (n, c)->
    @any(
      [ @flow_sequence, n, c ]
      [ @flow_mapping, n, c ]
      [ @single_quoted_scalar, n, c ]
      [ @double_quoted_scalar, n, c ]
    )



  # [056]
  # flow-mapping(n,c) ::=
  #   '{'
  #   separation-characters(n,c)?
  #   flow-mapping-context(n,c)?
  #   '}'

  flow_mapping: (n, c)->
    @all(
      @chr('{')
      @rep(0, 1, [ @separation_characters, n, c ])
      @rep(0, 1, [ @flow_mapping_context, n, c ])
      @chr('}')
    )



  # [057]
  # flow-mapping-entries(n,c) ::=
  #   flow-mapping-entry(n,c)
  #   separation-characters(n,c)?
  #   (
  #     ','
  #     separation-characters(n,c)?
  #     flow-mapping-entries(n,c)?
  #   )?

  flow_mapping_entries: (n, c)->
    @all(
      [ @flow_mapping_entry, n, c ]
      @rep(0, 1, [ @separation_characters, n, c ])
      @rep(0, 1,
        @all(
          @chr(',')
          @rep(0, 1, [ @separation_characters, n, c ])
          @rep(0, 1, [ @flow_mapping_entries, n, c ])
        )
      )
    )



  # [058]
  # flow-mapping-entry(n,c) ::=
  #     (
  #       '?'                           # Not followed by non-ws char
  #       separation-characters(n,c)
  #       flow-mapping-explicit-entry(n,c)
  #     )
  #   | flow-mapping-implicit-entry(n,c)

  flow_mapping_entry: (n, c)->
    @any(
      @all(
        @rgx(///
          \?
          #{ws_lookahead}
        ///y)
        [ @separation_characters, n, c ]
        [ @flow_mapping_explicit_entry, n, c ]
      )
      [ @flow_mapping_implicit_entry, n, c ]
    )



  # [59]
  # flow-mapping-explicit-entry(n,c) ::=
  #     flow-mapping-implicit-entry(n,c)
  #   | (
  #       empty-node
  #       empty-node
  #     )

  flow_mapping_explicit_entry: (n, c)->
    @any(
      [ @flow_mapping_implicit_entry, n, c ]
      @all(
        @empty_node
        @empty_node
      )
    )



  # [60]
  # flow-mapping-implicit-entry(n,c) ::=
  #     flow-mapping-yaml-key-entry(n,c)
  #   | flow-mapping-empty-key-entry(n,c)
  #   | flow-mapping-json-key-entry(n,c)

  flow_mapping_implicit_entry: (n, c)->
    @any(
      [ @flow_mapping_yaml_key_entry, n, c ]
      [ @flow_mapping_empty_key_entry, n, c ]
      [ @flow_mapping_json_key_entry, n, c ]
    )



  # [61]
  # flow-mapping-yaml-key-entry(n,c) ::=
  #   flow-yaml-node(n,c)
  #   (
  #       (
  #         separation-characters(n,c)?
  #         flow-mapping-separate-value(n,c)
  #       )
  #     | empty-node
  #   )

  flow_mapping_yaml_key_entry: (n, c)->
    @all(
      [ @flow_yaml_node, n, c ]
      @any(
        @all(
          @rep(0, 1, [ @separation_characters, n, c ])
          [ @flow_mapping_separate_value, n, c ]
        )
        @empty_node
      )
    )



  # [62]
  # flow-mapping-empty-key-entry(n,c) ::=
  #   empty-node
  #   flow-mapping-separate-value(n,c)

  flow_mapping_empty_key_entry: (n, c)->
    @all(
      @empty_node
      [ @flow_mapping_separate_value, n, c ]
    )



  # [63]
  # flow-mapping-separate-value(n,c) ::=
  #   ':'
  #   [ lookahead ≠ non-space-plain-scalar-character(c) ]
  #   (
  #       (
  #         separation-characters(n,c)
  #         flow-node(n,c)
  #       )
  #     | empty-node
  #   )

  flow_mapping_separate_value: (n, c)->
    @all(
      @chr(':')
      @chk('!', [ @non_space_plain_scalar_character, c ])
      @any(
        @all(
          [ @separation_characters, n, c ]
          [ @flow_node, n, c ]
        )
        @empty_node
      )
    )



  # [64]
  # flow-mapping-json-key-entry(n,c) ::=
  #   flow-json-node(n,c)
  #   (
  #       (
  #         separation-characters(n,c)?
  #         flow-mapping-adjacent-value(n,c)
  #       )
  #     | empty-node
  #   )

  flow_mapping_json_key_entry: (n, c)->
    @all(
      [ @flow_json_node, n, c ]
      @any(
        @all(
          @rep(0, 1, [ @separation_characters, n, c ])
          [ @flow_mapping_adjacent_value, n, c ]
        )
        @empty_node
      )
    )



  # [65]
  # flow-mapping-adjacent-value(n,c) ::=
  #   ':'
  #   (
  #       (
  #         separation-characters(n,c)?
  #         flow-node(n,c)
  #       )
  #     | empty-node
  #   )

  flow_mapping_adjacent_value: (n, c)->
    @all(
      @chr(':')
      @any(
        @all(
          @rep(0, 1, [ @separation_characters, n, c ])
          [ @flow_node, n, c ]
        )
        @empty_node
      )
    )



  # [66]
  # flow-pair(n,c) ::=
  #     (
  #       '?'                           # Not followed by non-ws char
  #       separation-characters(n,c)
  #       flow-mapping-explicit-entry(n,c)
  #     )
  #   | flow-pair-entry(n,c)

  flow_pair: (n, c)->
    @any(
      @all(
        @rgx(///
          \?
          #{ws_lookahead}
        ///)
        [ @separation_characters, n, c ]
        [ @flow_mapping_explicit_entry, n, c ]
      )
      [ @flow_pair_entry, n, c ]
    )



  # [67]
  # flow-pair-entry(n,c) ::=
  #     flow-pair-yaml-key-entry(n,c)
  #   | flow-mapping-empty-key-entry(n,c)
  #   | flow-pair-json-key-entry(n,c)

  flow_pair_entry: (n, c)->
    @any(
      [ @flow_pair_yaml_key_entry, n, c ]
      [ @flow_mapping_empty_key_entry, n, c ]
      [ @flow_pair_json_key_entry, n, c ]
    )



  # [68]
  # flow-pair-yaml-key-entry(n,c) ::=
  #   implicit-yaml-key(FLOW-KEY)
  #   flow-mapping-separate-value(n,c)

  flow_pair_yaml_key_entry: (n, c)->
    @all(
      [ @implicit_yaml_key, "flow-key" ]
      [ @flow_mapping_separate_value, n, c ]
    )



  # [69]
  # flow-pair-json-key-entry(n,c) ::=
  #   implicit-json-key(FLOW-KEY)
  #   flow-mapping-adjacent-value(n,c)

  flow_pair_json_key_entry: (n, c)->
    @all(
      [ @implicit_json_key, "flow-key" ]
      [ @flow_mapping_adjacent_value, n, c ]
    )



  # [70]
  # implicit-yaml-key(c) ::=
  #   flow-yaml-node(0,c)
  #   separation-blanks?
  #   /* At most 1024 characters altogether */

  implicit_yaml_key: (c)->
    @all(
      @max(1024)
      [ @flow_yaml_node, null, c ]
      @rep(0, 1, @rgx(re_separation_lines))
    )



  # [71]
  # implicit-json-key(c) ::=
  #   flow-json-node(0,c)
  #   separation-blanks?
  #   /* At most 1024 characters altogether */

  implicit_json_key: (c)->
    @all(
      @max(1024)
      [ @flow_json_node, null, c ]
      @rep(0, 1, @rgx(re_separation_lines))
    )



  # [72]
  # flow-yaml-node(n,c) ::=
  #     alias-node
  #   | flow-yaml-content(n,c)
  #   | (
  #       node-properties(n,c)
  #       (
  #           (
  #             separation-characters(n,c)
  #             flow-yaml-content(n,c)
  #           )
  #         | empty-node
  #       )
  #     )

  flow_yaml_node: (n, c)->
    @any(
      @alias_node
      [ @flow_yaml_content, n, c ]
      @all(
        [ @node_properties, n, c ]
        @any(
          @all(
            [ @separation_characters, n, c ]
            [ @flow_content, n, c ]
          )
          @empty_node
        )
      )
    )



  # [73]
  # flow-json-node(n,c) ::=
  #   (
  #     node-properties(n,c)
  #     separation-characters(n,c)
  #   )?
  #   flow-json-content(n,c)

  flow_json_node: (n, c)->
    @all(
      @rep(0, 1,
        @all(
          [ @node_properties, n, c ]
          [ @separation_characters, n, c ]
        )
      )
      [ @flow_json_content, n, c ]
    )



  # [074]
  # flow-sequence(n,c) ::=
  #   '['
  #   separation-characters(n,c)?
  #   flow-sequence-context(n,c)?
  #   ']'

  flow_sequence: (n, c)->
    @all(
      @chr('[')
      @rep(0, 1, [ @separation_characters, n, c ])
      @rep(0, 1, [ @flow_sequence_context, n, c ])
      @chr(']')
    )



  # [075]
  # flow-sequence-entries(n,c) ::=
  #   flow-sequence-entry(n,c)
  #   separation-characters(n,c)?
  #   (
  #     ','
  #     separation-characters(n,c)?
  #     flow-sequence-entries(n,c)?
  #   )?

  flow_sequence_entries: (n, c)->
    @all(
      [ @flow_sequence_entry, n, c ]
      @rep(0, 1, [ @separation_characters, n, c ])
      @rep(0, 1,
        @all(
          @chr(',')
          @rep(0, 1, [ @separation_characters, n, c ])
          @rep(0, 1, [ @flow_sequence_entries, n, c ])
        )
      )
    )



  # [76]
  # flow-sequence-entry(n,c) ::=
  #     flow-pair(n,c)
  #   | flow-node(n,c)

  flow_sequence_entry: (n, c)->
    @any(
      [ @flow_pair, n, c ]
      [ @flow_node, n, c ]
    )



  # [77]
  # double-quoted-scalar(n,c) ::=
  #   '"'
  #   double-quoted-text(n,c)
  #   '"'

  double_quoted_scalar: (n, c)->
    @all(
      @chr('"')
      [ @double_quoted_text, n, c ]
      @chr('"')
    )



  # [78]
  # double-quoted-text(n,BLOCK-KEY) ::= double-quoted-one-line
  # double-quoted-text(n,FLOW-KEY)  ::= double-quoted-one-line
  # double-quoted-text(n,FLOW-OUT)  ::= double-quoted-multi-line(n)
  # double-quoted-text(n,FLOW-IN)   ::= double-quoted-multi-line(n)

  double_quoted_text: (n, c)->
    @case c,
      'block-key': @rgx(double_quoted_one_line)
      'flow-in': [ @double_quoted_multi_line, n ]
      'flow-key': @rgx(double_quoted_one_line)
      'flow-out': [ @double_quoted_multi_line, n ]



  # [79]
  # double-quoted-multi-line(n) ::=
  #   double-quoted-first-line
  #   (
  #       double-quoted-next-line(n)
  #     | blank-character*
  #   )

  double_quoted_multi_line: (n)->
    @all(
      @rgx(re_double_quoted_first_line)
      @any(
        [ @double_quoted_next_line, n ]
        @rgx("#{blank_character}*")
      )
    )



  # [80]
  # double-quoted-one-line ::=
  #   non-break-double-quoted-character*

  double_quoted_one_line = ''

  i080 = ->
    [, double_quoted_one_line] = r ///
      #{non_break_double_quoted_character}*
    ///



  # [81]
  # double-quoted-first-line ::=
  #   (
  #     blank-character*
  #     non-space-double-quoted-character
  #   )*

  re_double_quoted_first_line = ''

  i081 = ->
    [, re_double_quoted_first_line] = r ///
      (?:
        #{blank_character}*
        #{non_space_double_quoted_character}
      )*
    ///



  # [82]
  # double-quoted-next-line(n) ::=
  #   (
  #       double-quoted-line-continuation(n)
  #     | flow-folded-whitespace(n)
  #   )
  #   (
  #     non-space-double-quoted-character
  #     double-quoted-first-line
  #     (
  #         double-quoted-next-line(n)
  #       | blank-character*
  #     )
  #   )?

  double_quoted_next_line: (n)->
    @all(
      @any(
        [ @double_quoted_line_continuation, n ]
        [ @flow_folded_whitespace, n ]
      )
      @rep(0, 1,
        @all(
          @rgx(re_non_space_double_quoted_character)
          @rgx(re_double_quoted_first_line)
          @any(
            [ @double_quoted_next_line, n ]
            @rgx("#{blank_character}*")
          )
        )
      )
    )



  # [83]
  # non-space-double-quoted-character ::=
  #     non-break-double-quoted-character
  #   - blank-character

  [non_space_double_quoted_character, re_non_space_double_quoted_character] = []

  i083 = ->
    [non_space_double_quoted_character, re_non_space_double_quoted_character] = r ///
      (?! #{blank_character})
      #{non_break_double_quoted_character}
    ///



  # [84]
  # non-break-double-quoted-character ::=
  #     double-quoted-scalar-escape-character
  #   | (
  #         json-character
  #       - '\'
  #       - '"'
  #     )

  non_break_double_quoted_character = ''

  i084 = ->
    [non_break_double_quoted_character] = r ///
      (?:
        #{double_quoted_scalar_escape_character}
      |
        (?! [ \\ " ])
        #{json_character}
      )
    ///



  # [85]
  # double-quoted-line-continuation(n) ::=
  #   blank-character*
  #   '\'
  #   line-break
  #   empty-line(n,FLOW-IN)*
  #   indentation-spaces-plus-maybe-more(n)

  double_quoted_line_continuation: (n)->
    @all(
      @rgx(///
        #{blank_character}*
        \\
        #{line_break}
      ///y)
      @rep(0, null, [ @empty_line, n, "flow-in" ])
      [ @indentation_spaces_plus_maybe_more, n ]
    )



  # [086]  # XXX fix typo in 1.3.0 spec
  # flow-mapping-context(n,FLOW-OUT)  ::= flow-sequence-entries(n,FLOW-IN)
  # flow-mapping-context(n,FLOW-IN)   ::= flow-sequence-entries(n,FLOW-IN)
  # flow-mapping-context(n,BLOCK-KEY) ::= flow-sequence-entries(n,FLOW-KEY)
  # flow-mapping-context(n,FLOW-KEY)  ::= flow-sequence-entries(n,FLOW-KEY)

  flow_mapping_context: (n, c)->
    @case c,
      'flow-out': [ @flow_mapping_entries, n, "flow-in" ]
      'flow-in': [ @flow_mapping_entries, n, "flow-in" ]
      'block-key': [ @flow_mapping_entries, n, "flow-key" ]
      'flow-key': [ @flow_mapping_entries, n, "flow-key" ]



  # [087]
  # flow-sequence-context(n,FLOW-OUT)  ::= flow-sequence-entries(n,FLOW-IN)
  # flow-sequence-context(n,FLOW-IN)   ::= flow-sequence-entries(n,FLOW-IN)
  # flow-sequence-context(n,BLOCK-KEY) ::= flow-sequence-entries(n,FLOW-KEY)
  # flow-sequence-context(n,FLOW-KEY)  ::= flow-sequence-entries(n,FLOW-KEY)

  flow_sequence_context: (n, c)->
    @case c,
      'flow-out': [ @flow_sequence_entries, n, "flow-in" ]
      'flow-in': [ @flow_sequence_entries, n, "flow-in" ]
      'block-key': [ @flow_sequence_entries, n, "flow-key" ]
      'flow-key': [ @flow_sequence_entries, n, "flow-key" ]



  # [88]
  # single-quoted-scalar(n,c) ::=
  #   "'"
  #   single-quoted-text(n,c)
  #   "'"

  single_quoted_scalar: (n, c)->
    @all(
      @chr("'")
      [ @single_quoted_text, n, c ]
      @chr("'")
    )



  # [89]
  # single-quoted-text(BLOCK-KEY) ::= single-quoted-one-line
  # single-quoted-text(FLOW-KEY)  ::= single-quoted-one-line
  # single-quoted-text(FLOW-OUT)  ::= single-quoted-multi-line(n)
  # single-quoted-text(FLOW-IN)   ::= single-quoted-multi-line(n)

  single_quoted_text: (n, c)->
    @case c,
      'block-key': @rgx(re_single_quoted_one_line)
      'flow-in': [ @single_quoted_multi_line, n ]
      'flow-key': @rgx(re_single_quoted_one_line)
      'flow-out': [ @single_quoted_multi_line, n ]



  # [90]
  # single-quoted-multi-line(n) ::=
  #   single-quoted-first-line
  #   (
  #       single-quoted-next-line(n)
  #     | blank-character*
  #   )

  single_quoted_multi_line: (n)->
    @all(
      @rgx(re_single_quoted_first_line)
      @any(
        [ @single_quoted_next_line, n ]
        @rgx("#{blank_character}*")
      )
    )



  # [91]
  # single-quoted-one-line ::=
  #   non-break-single-quoted-character*

  re_single_quoted_one_line = ''

  i091 = ->
    [, re_single_quoted_one_line] = r ///
      #{non_break_single_quoted_character}*
    ///



  # [92]
  # single-quoted-first-line ::=
  #   (
  #     blank-character*
  #     non-space-single-quoted-character
  #   )*

  [single_quoted_first_line, re_single_quoted_first_line] = []

  i092 = ->
    [single_quoted_first_line, re_single_quoted_first_line] = r ///
      (?:
        #{blank_character}*
        #{non_space_single_quoted_character}
      )*
    ///



  # [93]
  # single-quoted-next-line(n) ::=
  #   flow-folded-whitespace(n)
  #   (
  #     non-space-single-quoted-character
  #     single-quoted-first-line
  #     (
  #         single-quoted-next-line(n)
  #       | blank-character*
  #     )
  #   )?

  re_single_quoted_next_line = ''

  i093 = ->
    [, re_single_quoted_next_line] = r ///
      #{non_space_single_quoted_character}
      #{single_quoted_first_line}
    ///

  single_quoted_next_line: (n)->
    @all(
      [ @flow_folded_whitespace, n ]
      @rep(0, 1,
        @all(
          @rgx(re_single_quoted_next_line)
          @any(
            [ @single_quoted_next_line, n ]
            @rgx("#{blank_character}*")
          )
        )
      )
    )



  # [94]
  # non-space-single-quoted-character ::=
  #     non-break-single-quoted-character
  #   - blank-character

  non_space_single_quoted_character = ''

  i094 = ->
    [non_space_single_quoted_character] = r ///
      (?:
        (?! #{blank_character})
        #{non_break_single_quoted_character}
      )
    ///



  # [95]
  # non-break-single-quoted-character ::=
  #     single-quoted-escaped-single-quote
  #   | (
  #         json-character
  #       - "'"
  #     )

  non_break_single_quoted_character = ''

  i095 = ->
    [non_break_single_quoted_character] = r ///
      (?:
        #{single_quoted_escaped_single_quote}
      | (?:
          (?! ')
          #{json_character}
        )
      )
    ///



  # [96]
  # single-quoted-escaped-single-quote ::=
  #   "''"

  single_quoted_escaped_single_quote = ''

  i096 = ->
    [single_quoted_escaped_single_quote] = r ///
      '
      '
    ///



  # [97]
  # flow-plain-scalar(n,FLOW-OUT)  ::= plain-scalar-multi-line(n,FLOW-OUT)
  # flow-plain-scalar(n,FLOW-IN)   ::= plain-scalar-multi-line(n,FLOW-IN)
  # flow-plain-scalar(n,BLOCK-KEY) ::= plain-scalar-single-line(BLOCK-KEY)
  # flow-plain-scalar(n,FLOW-KEY)  ::= plain-scalar-single-line(FLOW-KEY)

  flow_plain_scalar: (n, c)->
    @case c,
      'block-key': [ @plain_scalar_single_line, c ]
      'flow-in': [ @plain_scalar_multi_line, n, c ]
      'flow-key': [ @plain_scalar_single_line, c ]
      'flow-out': [ @plain_scalar_multi_line, n, c ]



  # [98]
  # plain-scalar-multi-line(n,c) ::=
  #   plain-scalar-single-line(c)
  #   plain-scalar-next-line(n,c)*

  plain_scalar_multi_line: (n, c)->
    @all(
      [ @plain_scalar_single_line, c ]
      @rep(0, null, [ @plain_scalar_next_line, n, c ])
    )



  # [99]
  # plain-scalar-single-line(c) ::=
  #   plain-scalar-first-character(c)
  #   plain-scalar-line-characters(c)

  plain_scalar_single_line: (c)->
    @all(
      [ @plain_scalar_first_character, c ]
      [ @plain_scalar_line_characters, c ]
    )



  # [100]
  # plain-scalar-next-line(n,c) ::=
  #   flow-folded-whitespace(n)
  #   plain-scalar-characters(c)
  #   plain-scalar-line-characters(c)

  plain_scalar_next_line: (n, c)->
    @all(
      [ @flow_folded_whitespace, n ]
      [ @plain_scalar_characters, c ]
      [ @plain_scalar_line_characters, c ]
    )



  # [101]
  # plain-scalar-line-characters(c) ::=
  #   (
  #     blank-character*
  #     plain-scalar-characters(c)
  #   )*

  plain_scalar_line_characters: (c)->
    @rep(0, null,
      @all(
        @rgx("#{blank_character}*")
        [ @plain_scalar_characters, c ]
      )
    )



  # [102]
  # plain-scalar-first-character(c) ::=
  #     (
  #         non-space-character
  #       - '?'                         # Mapping key
  #       - ':'                         # Mapping value
  #       - '-'                         # Sequence entry
  #       - '{'                         # Mapping start
  #       - '}'                         # Mapping end
  #       - '['                         # Sequence start
  #       - ']'                         # Sequence end
  #       - ','                         # Entry separator
  #       - '#'                         # Comment
  #       - '&'                         # Anchor
  #       - '*'                         # Alias
  #       - '!'                         # Tag
  #       - '|'                         # Literal scalar
  #       - '>'                         # Folded scalar
  #       - "'"                         # Single quote
  #       - '"'                         # Double quote
  #       - '%'                         # Directive
  #       - '@'                         # Reserved
  #       - '`'                         # Reserved
  #     )
  #   | (
  #       ( '?' | ':' | '-' )
  #       [ lookahead = non-space-plain-scalar-character(c) ]
  #     )

  plain_scalar_first_character: (c)->
    @any(
      @rgx(///
        (?!
          [
            -
            ?
            :
            ,
            [
            \]
            {
            }
            \x23     # '#'
            &
            *
            !
            |
            >
            '
            "
            %
            @
            `
          ]
        )
        #{non_space_character}
      ///yu)
      @all(
        @rgx(///
          [
            ?
            :
            -
          ]
        ///y)
        @chk('=', [ @non_space_plain_scalar_character, c ])
      )
    )



  # [103]
  # plain-scalar-characters(c) ::=
  #     (
  #         non-space-plain-scalar-character(c)
  #       - ':'
  #       - '#'
  #     )
  #   | (
  #       [ lookbehind = non-space-character ]
  #       '#'
  #     )
  #   | (
  #       ':'
  #       [ lookahead = non-space-plain-scalar-character(c) ]
  #     )

# TODO
#   plain_scalar_characters = (c)->
#     non_space_plain_scalar_character = ...
#     ///
#       (?:
#         (?:
#           (?!
#             [
#               :
#               \x23        # '#'
#             ]
#           )
# 
#     ///yu

  plain_scalar_characters: (c)->
    @any(
      @but(
        [ @non_space_plain_scalar_character, c ]
        @chr(':')
        @chr('#')
      )
      @all(
        @chk('<=', @rgx(re_non_space_character))
        @chr('#')
      )
      @all(
        @chr(':')
        @chk('=', [ @non_space_plain_scalar_character, c ])
      )
    )



  # [104]
  # non-space-plain-scalar-character(FLOW-OUT)  ::= block-plain-scalar-character
  # non-space-plain-scalar-character(FLOW-IN)   ::= flow-plain-scalar-character
  # non-space-plain-scalar-character(BLOCK-KEY) ::= block-plain-scalar-character
  # non-space-plain-scalar-character(FLOW-KEY)  ::= flow-plain-scalar-character

  non_space_plain_scalar_character: (c)->
    @case c,
      'block-key': @block_plain_scalar_character
      'flow-in': @flow_plain_scalar_character
      'flow-key': @flow_plain_scalar_character
      'flow-out': @block_plain_scalar_character



  # [105]
  # block-plain-scalar-character ::=
  #   non-space-character

  block_plain_scalar_character: ->
    @rgx(///
      (?: #{non_space_character} )
    ///yu)



  # [106]
  # flow-plain-scalar-character ::=
  #     non-space-characters
  #   - flow-collection-indicators

  flow_plain_scalar_character: ->
    @rgx(///
      (?:
        (?!
          #{flow_collection_indicator}
        )
        #{non_space_character}
      )
    ///yu)



  # [107]
  # alias-node ::=
  #   '*'
  #   anchor-name

  alias_node: ->
    @rgx(///
      \*
      #{anchor_name}
    ///yu)



  # [108]
  # empty-node ::=
  #   ""

  empty_node: ->
    @empty



  # [109]
  # indentation-spaces(0) ::=
  #   ""

  indentation_spaces: ->
    @rgx(/// #{space_character}* ///y)

  # indentation-spaces(n+1) ::=
  #   space-character
  #   indentation-spaces(n)

  # When n≥0

  indentation_spaces_n: (n)->
    @rgx(/// #{space_character}{#{n}} ///y)



  # [110]
  # indentation-spaces-less-than(1) ::=
  #   ""

  # # When n≥1

  indentation_spaces_less_than: (n)->
    @all(
      @indentation_spaces()
      @lt(@len(@match), n)
    )



  # [111]
  # indentation-spaces-less-or-equal(0) ::=
  #   ""

  # # When n≥0

  indentation_spaces_less_or_equal: (n)->
    @all(
      @indentation_spaces()
      @le(@len(@match), n)
    )



  # [112]
  # line-prefix-spaces(n,BLOCK-OUT) ::= indentation-spaces-exact(n)
  # line-prefix-spaces(n,BLOCK-IN)  ::= indentation-spaces-exact(n)
  # line-prefix-spaces(n,FLOW-OUT)  ::= indentation-spaces-plus-maybe-more(n)
  # line-prefix-spaces(n,FLOW-IN)   ::= indentation-spaces-plus-maybe-more(n)

  line_prefix_spaces: (n, c)->
    @case c,
      'block-in': [ @indentation_spaces_exact, n ]
      'block-out': [ @indentation_spaces_exact, n ]
      'flow-in': [ @indentation_spaces_plus_maybe_more, n ]
      'flow-out': [ @indentation_spaces_plus_maybe_more, n ]



  # [113]
  # indentation-spaces-exact(n) ::=
  #   indentation-spaces(n)

  indentation_spaces_exact: (n)->
    @indentation_spaces_n(n)



  # [114]
  # indentation-spaces-plus-maybe-more(n) ::=
  #   indentation-spaces(n)
  #   separation-blanks?

  indentation_spaces_plus_maybe_more: (n)->
    @all(
      @indentation_spaces_n(n)
      @rep(0, 1, @rgx(re_separation_lines))
    )



  # [115]
  # flow-folded-whitespace(n) ::=
  #   separation-blanks?
  #   folded-whitespace(n,FLOW-IN)
  #   indentation-spaces-plus-maybe-more(n)

  flow_folded_whitespace: (n)->
    @all(
      @rep(0, 1, @rgx(re_separation_lines))
      [ @folded_whitespace, n, "flow-in" ]
      [ @indentation_spaces_plus_maybe_more, n ]
    )



  # [116]
  # folded-whitespace(n,c) ::=
  #     (
  #       line-break
  #       empty-line(n,c)+
  #     )
  #   | break-as-space
  # A.4.4. Comments

  folded_whitespace: (n, c)->
    @any(
      @all(
        @rgx(re_line_break)
        @rep(1, null, [ @empty_line, n, c ])
      )
      @rgx(re_break_as_space)
    )



  # [117]
  # comment-lines ::=
  #     comment-line+
  #   | <start-of-line>

  comment_lines: ->
    @all(
      @any(
        @comment_line
        @start_of_line
      )
      @rep(0, null, @l_comment)
    )



  # [118]
  # comment-line ::=
  #   separation-blanks
  #   comment-content?
  #   line-ending

  comment_line: ->
    @all(
      @rep(0, 1,
        @all(
          @rgx(re_separation_lines)
          @rgx(/// #{comment_content}? ///yu, true)
        )
      )
      @rgx(re_line_ending, true)
    )



  # [119]
  # comment-content ::=
  #   '#'
  #   non-break-character*

  comment_content = ''

  i119 = ->
    [comment_content] = r ///
      (?:
        \x23
        #{non_break_character}*
      )
    ///u



  # [120]
  # empty-line(n,c) ::=
  #   (
  #       line-prefix-spaces(n,c)
  #     | indentation-spaces-less-than(n)
  #   )
  #   break-as-line-feed

  empty_line: (n, c)->
    @all(
      @any(
        [ @line_prefix_spaces, n, c ]
        [ @indentation_spaces_less_than, n ]
      )
      @rgx(re_break_as_line_feed)
    )



  # [121]
  # separation-characters(n,BLOCK-OUT) ::= separation-lines(n)
  # separation-characters(n,BLOCK-IN)  ::= separation-lines(n)
  # separation-characters(n,FLOW-OUT)  ::= separation-lines(n)
  # separation-characters(n,FLOW-IN)   ::= separation-lines(n)
  # separation-characters(n,BLOCK-KEY) ::= separation-blanks
  # separation-characters(n,FLOW-KEY)  ::= separation-blanks

  separation_characters: (n, c)->
    @case c,
      'block-in': [ @separation_lines, n ]
      'block-key': @rgx(re_separation_lines)
      'block-out': [ @separation_lines, n ]
      'flow-in': [ @separation_lines, n ]
      'flow-key': @rgx(re_separation_lines)
      'flow-out': [ @separation_lines, n ]



  # [122]
  # separation-lines(n) ::=
  #     (
  #       comment-lines
  #       indentation-spaces-plus-maybe-more(n)
  #     )
  #   | separation-blanks

  [separation_lines, re_separation_lines] = []

  i123 = ->
    [separation_lines, re_separation_lines] = r ///
      (?:
        #{blank_character}+
      | #{start_of_line}
      )
    ///

  separation_lines: (n)->
    @any(
      @all(
        @comment_lines
        [ @indentation_spaces_plus_maybe_more, n ]
      )
      @rgx(re_separation_lines)
    )



  # [124]
  # yaml-directive-line ::=
  #   "YAML"
  #   separation-blanks
  #   yaml-version-number

  yaml_directive_line: ->
    @all(
      @rgx(///
        (?:
          Y A M L
          #{separation_lines}
        )
      ///y)
      @yaml_version_number
    )



  # [125]
  # yaml-version-number ::=
  #   decimal-digit+
  #   '.'
  #   decimal-digit+

  yaml_version_number: ->
    @rgx(///
      #{decimal_digit}+
      \.
      #{decimal_digit}+
    ///y)



  # [126]
  # reserved-directive-line ::=
  #   directive-name
  #   (
  #     separation-blanks
  #     directive-parameter
  #   )*

  reserved_directive_line: ->
    @rgx(///
      #{directive_name}
      (?:
        #{separation_lines}
        #{directive_parameter}
      )*
    ///yu)



  # [127]
  # directive-name ::=
  #   non-space-character+

  directive_name = ''

  i127 = ->
    [directive_name] = r ///
      #{non_space_character}+
    ///u



  # [128]
  # directive-parameter ::=
  #   non-space-character+

  directive_parameter = ''

  i128 = ->
    [directive_parameter] = r ///
      #{non_space_character}+
    ///u



  # [129]
  # tag-directive-line ::=
  #   "TAG"
  #   separation-blanks
  #   tag-handle
  #   separation-blanks
  #   tag-prefix

  tag_directive_line: ->
    @all(
      @rgx(///
        T A G
        #{separation_lines}
      ///y)
      @tag_handle
      @rgx(re_separation_lines)
      @tag_prefix
    )



  # [130]
  # tag-handle ::=
  #     named-tag-handle
  #   | secondary-tag-handle
  #   | primary-tag-handle

  [tag_handle, re_tag_handle] = []

  i130 = ->
    [tag_handle, re_tag_handle] = r ///
      (?:
        #{named_tag_handle}
      | #{secondary_tag_handle}
      | #{primary_tag_handle}
      )
    ///

  tag_handle: ->
    @rgx(re_tag_handle)



  # [131]
  # named-tag-handle ::=
  #   '!'
  #   word-character+
  #   '!'

  named_tag_handle = ''

  i131 = ->
    [named_tag_handle] = r ///
      !
      #{word_character}+
      !
    ///



  # [132]
  # secondary-tag-handle ::=
  #   "!!"

  secondary_tag_handle = ''

  i132 = ->
    secondary_tag_handle = "!!"



  # [133]
  # primary-tag-handle ::=
  #   '!'

  primary_tag_handle = ''

  i133 = ->
    primary_tag_handle = "!"



  # [134]
  # tag-prefix ::=
  #     local-tag-prefix
  #   | global-tag-prefix

  tag_prefix: ->
    @rgx(///
      (?:
        #{local_tag_prefix}
      | #{global_tag_prefix}
      )
    ///y)



  # [135]
  # local-tag-prefix ::=
  #   '!'
  #   uri-character*

  local_tag_prefix = ''

  i135 = ->
    [local_tag_prefix] = r ///
      !
      #{uri_character}*
    ///



  # [136]
  # global-tag-prefix ::=
  #   tag-character
  #   uri-character*

  global_tag_prefix = ''

  i136 = ->
    [global_tag_prefix] = r ///
      #{tag_char}
      #{uri_character}*
    ///



  # [137]
  # node-properties(n,c) ::=
  #     (
  #       anchor-property
  #       (
  #         separation-characters(n,c)
  #         tag-property
  #       )?
  #     )
  #   | (
  #       tag-property
  #       (
  #         separation-characters(n,c)
  #         anchor-property
  #       )?
  #     )

  node_properties: (n, c)->
    @any(
      @all(
        @tag_property
        @rep(0, 1,
          @all(
            [ @separation_characters, n, c ]
            @anchor_property
          )
        )
      )
      @all(
        @anchor_property
        @rep(0, 1,
          @all(
            [ @separation_characters, n, c ]
            @tag_property
          )
        )
      )
    )



  # [138]
  # anchor-property ::=
  #   '&'
  #   anchor-name

  anchor_property: ->
    @rgx(///
      &
      #{anchor_name}
    ///yu)



  # [139]
  # anchor-name ::=
  #   anchor-character+

  anchor_name = ''

  i139 = ->
    [anchor_name] = r ///
      (?:
        #{anchor_character}
      )+
    ///u



  # [140]
  # anchor-character ::=
  #     non-space-character
  #   - flow-collection-indicators

  anchor_character = ''

  i140 = ->
    [anchor_character] = r ///
      (?:
        (?!
          #{flow_collection_indicator}
        )
        #{non_space_character}
      )+
    ///u



  # [141]
  # tag-property ::=
  #     verbatim-tag
  #   | shorthand-tag
  #   | non-specific-tag

  tag_property: ->
    @rgx(///
      (?:
        #{verbatim_tag}
      | #{shorthand_tag}
      | #{non_specific_tag}
      )
    ///y)



  # [142]
  # verbatim-tag ::=
  #   "!<"
  #   uri-character+
  #   '>'

  verbatim_tag = ''

  i142 = ->
    [verbatim_tag] = r ///
        (?:
          !
          <
            #{uri_character}+
          >
        )
    ///



  # [143]
  # shorthand-tag ::=
  #   tag-handle
  #   tag-character+

  shorthand_tag = ''

  i143 = ->
    [shorthand_tag] = r ///
      (
        #{tag_handle}
        #{tag_char}+
      )
    ///



  # [144]
  # non-specific-tag ::=
  #   '!'

  non_specific_tag = "!"



  # [145]
  # byte-order-mark ::=
  #   xFEFF

  byte_order_mark = ''

  i145 = ->
    byte_order_mark = "\u{FEFF}"



  # [146]
  # yaml-character ::=
  #                                     # 8 bit
  #     x09                             # Tab
  #   | x0A                             # Line feed
  #   | x0D                             # Carriage return
  #   | [x20-x7E]                       # Printable ASCII
  #                                     # 16 bit
  #   | x85                             # Next line (NEL)
  #   | [xA0-xD7FF]                     # Basic multilingual plane (BMP)
  #   | [xE000-xFFFD]                   # Additional unicode areas
  #   | [x010000-x10FFFF]               # 32 bit

  yaml_character = ''

  i146 = ->
    [yaml_character] = r ///
      [
        \x09
        \x0A
        \x0D
        \x20-\x7E
        \x85
        \xA0-\uD7FF
        \uE000-\uFFFD
        \u{10000}-\u{10FFFF}
      ]
    ///u



  # [147]
  # json-character ::=
  #     x09                             # Tab
  #   | [x20-x10FFFF]                   # Non-C0-control characters

  json_character = ''

  i147 = ->
    [json_character] = r ///
      [
        \x09
        \x20-\u{10FFFF}
      ]
    ///u



  # [148]
  # non-space-character ::=
  #     non-break-character
  #   - blank-character

  [non_space_character, re_non_space_character] = []

  i148 = ->
    [non_space_character, re_non_space_character] = r ///
      (?:
        (?!
          #{blank_character}
        )
        #{non_break_character}
      )
    ///u



  # [149]
  # non-break-character ::=
  #     yaml-character
  #   - x0A
  #   - x0D
  #   - byte-order-mark

  [non_break_character, re_non_break_character] = []

  i149 = ->
    [non_break_character, re_non_break_character] = r ///
      (?:
        (?!
          [
            \x0A
            \x0D
            #{byte_order_mark}
          ]
        )
        #{yaml_character}
      )
    ///u



  # [150]
  # blank-character ::=
  #     x20                             # Space
  #   | x09                             # Tab

  [blank_character, ws_lookahead] = []

  i150 = ->
    [blank_character] = r ///
      [
        #{space_character}
        \t
      ]
    ///

    [ws_lookahead] = r ///
      (?=
        #{end_of_file}
      | #{blank_character}
      | #{line_break}
      )
    ///



  # [151]
  # space-character ::=
  #   x20

  space_character = ''

  i151 = ->
    space_character = "\x20"



  # [152]
  # line-ending ::=
  #     line-break
  #   | <end-of-input>

  [line_ending, re_line_ending] = []

  i152 = ->
    [line_ending, re_line_ending] = r ///
      (?:
        #{line_break}
      | #{end_of_file}
      )
    ///



  # [153]
  # break-as-space ::=
  #   line-break

  re_break_as_space = ''

  i153 = ->
    re_break_as_space = re_line_break



  # [154]
  # break-as-line-feed ::=
  #   line-break

  re_break_as_line_feed = ''

  i154 = ->
    re_break_as_line_feed = re_line_break



  # [155]
  # line-break ::=
  #     (
  #       x0D                           # Carriage return
  #       x0A                           # Line feed
  #     )
  #   | x0D
  #   | x0A

  [line_break, re_line_break] = []

  i155 = ->
    [line_break, re_line_break] = r ///
      (?:
        (?:
          \x0D
          \x0A
        )
      | \x0D
      | \x0A
      )
    ///



  # XXX Rename to flow-collection-indicator
  # [156]
  # flow-collection-indicators ::=
  #     '{'                             # Flow mapping start
  #   | '}'                             # Flow mapping end
  #   | '['                             # Flow sequence start
  #   | ']'                             # Flow sequence end

  # [156] 023
  # c-flow-indicator ::=
  #   ',' | '[' | ']' | '{' | '}'

  [flow_collection_indicator, flow_collection_indicator_s] = []

  i156 = ->
    [flow_collection_indicator, , flow_collection_indicator_s] = r ///
      [
        ,
        [
        \]
        {
        }
      ]
    ///



  # [157]
  # double-quoted-scalar-escape-character ::=
  #   '\'
  #   (
  #       '0'
  #     | 'a'
  #     | 'b'
  #     | 't' | x09
  #     | 'n'
  #     | 'v'
  #     | 'f'
  #     | 'r'
  #     | 'e'
  #     | x20
  #     | '"'
  #     | '/'
  #     | '\'
  #     | 'N'
  #     | '_'
  #     | 'L'
  #     | 'P'
  #     | ( 'x' hexadecimal-digit{2} )
  #     | ( 'u' hexadecimal-digit{4} )
  #     | ( 'U' hexadecimal-digit{8} )
  #   )

  double_quoted_scalar_escape_character = ''

  i157 = ->
    [double_quoted_scalar_escape_character] = r ///
      \\
      (?:
        [
          0
          a
          b
          t
          \t
          n
          v
          f
          r
          e
          \x20
          "
          /
          \\
          N
          _
          L
          P
        ]
      | x #{hexadecimal_digit}{2}
      | u #{hexadecimal_digit}{4}
      | U #{hexadecimal_digit}{8}
      )
    ///



  # [158]
  # tag-character ::=
  #     uri-character
  #   - '!'
  #   - flow-collection-indicators

  tag_char = ''

  i158 = ->
    [tag_char] = r ///
      (?:
        (?!
          [
            !
            #{flow_collection_indicator_s}
          ]
        )
        #{uri_character}
      )
    ///



  # [159]
  # uri-character ::=
  #     (
  #       '%'
  #       hexadecimal-digit{2}
  #     )
  #   | word-character
  #   | '#'
  #   | ';'
  #   | '/'
  #   | '?'
  #   | ':'
  #   | '@'
  #   | '&'
  #   | '='
  #   | '+'
  #   | '$'
  #   | ','
  #   | '_'
  #   | '.'
  #   | '!'
  #   | '~'
  #   | '*'
  #   | "'"
  #   | '('
  #   | ')'
  #   | '['
  #   | ']'

  uri_character = ''

  i159 = ->
    [uri_character] = r ///
      (?:
        % #{hexadecimal_digit}{2}
      | [
          #{word_character_s}
          \x23
          ;
          /
          ?
          :
          @
          &
          =
          +
          $
          ,
          _
          .
          !
          ~
          *
          '
          (
          )
          [
          \]
        ]
      )
    ///



  # [160]
  # word-character ::=
  #     decimal-digit
  #   | ascii-alpha-character
  #   | '-'

  [word_character, , word_character_s] = []

  i160 = ->
    [word_character, , word_character_s] = r ///
      [
        #{decimal_digit_s}
        #{ascii_alpha_character_s}
        \-
      ]
    ///



  # [161]
  # hexadecimal-digit ::=
  #     decimal-digit
  #   | [x41-x46]                       # A-F
  #   | [x61-x66]                       # a-f

  hexadecimal_digit = ''

  i161 = ->
    [hexadecimal_digit] = r ///
      [
        #{decimal_digit_s}
        A - F
        a - f
      ]
    ///



  # [162]
  # decimal-digit ::=
  #   [x30-x39]                         # 0-9

  [decimal_digit, decimal_digit_s] = []

  i162 = ->
    [decimal_digit, , decimal_digit_s] = r ///
      [
        0 - 9
      ]
    ///



  # [163]
  # decimal-digit-1-9 ::=
  #   [x31-x39]                         # 0-9

  re_decimal_digit_1_9 = ''

  i163 = ->
    [re_decimal_digit_1_9] = r ///
      [
        0 - 9
      ]
    ///



  # [164]
  # ascii-alpha-character ::=
  #     [x41-x5A]                       # A-Z
  #   | [x61-x7A]                       # a-z

  ascii_alpha_character_s = ''

  i164 = ->
    [, , ascii_alpha_character_s] = r ///
      [
        A - Z
        a - z
      ]
    ///

#------------------------------------------------------------------------------


  # XXX Not sure if this can be replaced by s_b_comment:

  # [x078]
  # l-comment ::=
  #   s-separate-in-line c-nb-comment-text?
  #   b-comment

  l_comment: ->
    @all(
      @rgx(re_separation_lines)
      @rgx(///
        #{comment_content}*
        #{line_ending}
      ///yu)
    )



  # Call the variable initialization functions in the order needed for
  # JavaScript to be correct.
  init() for init in [
    i146
    i147
    i145
    i156
    i155
    i154
    i162
    i163
    i151
    i150
    i149
    i148
    i161
    i164
    i160
    i159
    i158
    i157
    i153
    i152
    i123
    i133
    i132
    i131
    i130
    i135
    i136
    i142
    i143
    i140
    i139
    i128
    i127
    i119
    i051
    i096
    i095
    i094
    i091
    i092
    i093
    i084
    i083
    i081
    i080
    i004
  ]
