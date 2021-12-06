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
  init = []


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
      @rep2(0, null,
        @any(
          @all(
            @document_suffix
            @rep(0, null, @document_prefix)
            @rep2(0, 1, @any_document)
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
      @rep(0, 1, @chr(c_byte_order_mark))
      @rep2(0, null, @l_comment)
    )



  # [003]
  # document-suffix ::=
  #   document-end-indicator
  #   comment-lines

  document_suffix: ->
    @all(
      @document_end_indicator
      @s_l_comments
    )



  # [004]
  # document-start-indicator ::=
  #   "---"

  [document_start_indicator, re_document_start_indicator] = []
  init.push ->
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
          @e_node
          @s_l_comments
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
        @ns_yaml_directive
        @ns_tag_directive
        @rgx(re_ns_reserved_directive)
      )
      @s_l_comments
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
          (?:
            #{b_char}
          | #{s_white}
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
      [ @s_separate, n + 1, "flow-out" ]
      [ @ns_flow_node, n + 1, "flow-out" ]
      @s_l_comments
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
          [ @s_separate, n + 1, c ]
          # XXX replace with `node-properties`
          @any(
            @all(
              [ @c_ns_properties, n + 1, c ]
              @s_l_comments
            )
            @all(
              @c_ns_tag_property
              @s_l_comments
            )
            @all(
              @c_ns_anchor_property
              @s_l_comments
            )
          )
        )
      )
      @s_l_comments
      @any(
        # [ @block_sequence_context, [ @seq_spaces, n, c ] ]
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
      [ @s_separate, n + 1, c ]
      @rep(0, 1,
        @all(
          [ @c_ns_properties, n + 1, c ]
          [ @s_separate, n + 1, c ]
        )
      )
      @any(
        [ @c_l_literal, n ]
        [ @c_l_folded, n ]
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
          @rgx(s_indent_n(n + m))
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
        @e_node
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
      @rgx(s_indent_n(n))
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
        @e_node
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
      [ @c_s_implicit_json_key, "block-key" ],
      [ @ns_s_implicit_yaml_key, "block-key" ]
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
          @e_node
          @s_l_comments
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
          @rgx(s_indent_n(n))
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
          @rgx(s_indent_n(n + m))
          [ @c_l_block_seq_entry, n + m ]
        )
      )
    )



  # [028]
  # block-sequence-entry(n) ::=
  #   '-'
  #   [ lookahead ≠ non-space-character ]
  #   block-indented-node(n,BLOCK-IN)

  c_l_block_seq_entry: (n)->
    @all(
      @rgx(///
        -
        #{ws_lookahead}
      ///y)
      @chk('!', @rgx(re_ns_char))
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
        @rgx(s_indent_n(m))
        @any(
          [ @compact_sequence, n + 1 + m ]
          [ @compact_mapping, n + 1 + m ]
        )
      )
      [ @block_node, n, c ]
      @all(
        @e_node
        @s_l_comments
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
      [ @c_l_block_seq_entry, n ]
      @rep(0, null,
        @all(
          @rgx(s_indent_n(n))
          [ @c_l_block_seq_entry, n ]
        )
      )
    )




#------------------------------------------------------------------------------
  # [001]
  # c-printable ::=
  #   x:9 | x:A | x:D | [x:20-x:7E]
  #   | x:85 | [x:A0-x:D7FF] | [x:E000-x:FFFD]
  #   | [x:10000-x:10FFFF]

  [c_printable] = r ///
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



  # [002]
  # nb-json ::=
  #   x:9 | [x:20-x:10FFFF]

  [nb_json] = r ///
    [
      \x09
      \x20-\u{10FFFF}
    ]
  ///u



  # [003]
  # c-byte-order-mark ::=
  #   x:FEFF

  c_byte_order_mark = "\u{FEFF}"



  # [022]               # XXX rule not in 1.3
  # c-indicator ::=
  #   '-' | '?' | ':' | ',' | '[' | ']' | '{' | '}'
  #   | '#' | '&' | '*' | '!' | '|' | '>' | ''' | '"'
  #   | '%' | '@' | '`'

  [c_indicator] = r ///
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
  ///



  # [023]
  # c-flow-indicator ::=
  #   ',' | '[' | ']' | '{' | '}'

  [c_flow_indicator, , c_flow_indicator_s] = r ///
    [
      ,
      [
      \]
      {
      }
    ]
  ///



  # [026]
  # b-char ::=
  #   b-line-feed | b-carriage-return

  [b_char, re_b_char, b_char_s] = r ///
    [
      \x0A
      \x0D
    ]
  ///



  # [027]
  # nb-char ::=
  #   c-printable - b-char - c-byte-order-mark

  [nb_char, re_nb_char] = r ///
    (?:
      (?!
        [
          #{b_char_s}
          #{c_byte_order_mark}
        ]
      )
      #{c_printable}
    )
  ///u



  # [028]
  # b-break ::=
  #   ( b-carriage-return b-line-feed )
  #   | b-carriage-return
  #   | b-line-feed

  [b_break, re_b_break] = r ///
    (?:
      (?:
        \x0D
        \x0A
      )
    | \x0D
    | \x0A
    )
  ///



  # [029]
  # b-as-line-feed ::=
  #   b-break

  re_b_as_line_feed = re_b_break



  # [030]
  # b-non-content ::=
  #   b-break

  b_non_content = b_break
  re_b_non_content = re_b_break



  # [031]
  # s-space ::=
  #   x:20

  s_space = "\x20"



  # [033]
  # s-white ::=
  #   s-space | s-tab

  [s_white] = r ///
    [
      #{s_space}
      \t
    ]
  ///



  [ws_lookahead] = r ///
    (?=
      #{end_of_file}
    | #{s_white}
    | #{b_break}
    )
  ///



  # [034]
  # ns-char ::=
  #   nb-char - s-white

  [ns_char, re_ns_char] = r ///
    (?:
      (?!
        #{s_white}
      )
      #{nb_char}
    )
  ///u



  # [035]
  # ns-dec-digit ::=
  #   [x:30-x:39]

  [ns_dec_digit, , ns_dec_digit_s] = r ///
    [
      0 - 9
    ]
  ///



  # [036]
  # ns-hex-digit ::=
  #   ns-dec-digit
  #   | [x:41-x:46] | [x:61-x:66]

  [ns_hex_digit] = r ///
    [
      #{ns_dec_digit_s}
      A - F
      a - f
    ]
  ///



  # [037]
  # ns-ascii-letter ::=
  #   [x:41-x:5A] | [x:61-x:7A]

  [, , ns_ascii_letter_s] = r ///
    [
      A - Z
      a - z
    ]
  ///



  # [038]
  # ns-word-char ::=
  #   ns-dec-digit | ns-ascii-letter | '-'

  [ns_word_char, , ns_word_char_s] = r ///
    [
      #{ns_dec_digit_s}
      #{ns_ascii_letter_s}
      \-
    ]
  ///



  # [039]
  # ns-uri-char ::=
  #   '%' ns-hex-digit ns-hex-digit | ns-word-char | '#'
  #   | ';' | '/' | '?' | ':' | '@' | '&' | '=' | '+' | '$' | ','
  #   | '_' | '.' | '!' | '~' | '*' | ''' | '(' | ')' | '[' | ']'

  [ns_uri_char] = r ///
    (?:
      % #{ns_hex_digit}{2}
    | [
        #{ns_word_char_s}
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



  # [040]
  # ns-tag-char ::=
  #   ns-uri-char - '!' - c-flow-indicator

  [ns_tag_char] = r ///
    (?:
      (?!
        [
          !
          #{c_flow_indicator_s}
        ]
      )
      #{ns_uri_char}
    )
  ///



  # [062]
  # c-ns-esc-char ::=
  #   '\'
  #   ( ns-esc-null | ns-esc-bell | ns-esc-backspace
  #   | ns-esc-horizontal-tab | ns-esc-line-feed
  #   | ns-esc-vertical-tab | ns-esc-form-feed
  #   | ns-esc-carriage-return | ns-esc-escape | ns-esc-space
  #   | ns-esc-double-quote | ns-esc-slash | ns-esc-backslash
  #   | ns-esc-next-line | ns-esc-non-breaking-space
  #   | ns-esc-line-separator | ns-esc-paragraph-separator
  #   | ns-esc-8-bit | ns-esc-16-bit | ns-esc-32-bit )

  [c_ns_esc_char] = r ///
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
    | x #{ns_hex_digit}{2}
    | u #{ns_hex_digit}{4}
    | U #{ns_hex_digit}{8}
    )
  ///



  # [063]
  [, re_s_indent] = r ///
    #{s_space}*
  ///

  s_indent_n = (n)->
    /// #{s_space}{#{n}} ///y



  # [064]
  # s-indent(<n) ::=
  #   s-space{m} <where_m_<_n>

  s_indent_lt: (n)->
    @all(
      @rgx(re_s_indent)
      @lt(@len(@match), n)
    )



  # [065]
  # s-indent(<=n) ::=
  #   s-space{m} <where_m_<=_n>

  s_indent_le: (n)->
    @all(
      @rgx(re_s_indent)
      @le(@len(@match), n)
    )



  # [066]
  # s-separate-in-line ::=
  #   s-white+ | <start_of_line>

  [s_separate_in_line, re_s_separate_in_line] = r ///
    (?:
      #{s_white}+
    | #{start_of_line}
    )
  ///



  # [067]
  # s-line-prefix(n,c) ::=
  #   ( c = block-out => s-block-line-prefix(n) )
  #   ( c = block-in => s-block-line-prefix(n) )
  #   ( c = flow-out => s-flow-line-prefix(n) )
  #   ( c = flow-in => s-flow-line-prefix(n) )

  s_line_prefix: (n, c)->
    @case c,
      'block-in': [ @s_block_line_prefix, n ]
      'block-out': [ @s_block_line_prefix, n ]
      'flow-in': [ @s_flow_line_prefix, n ]
      'flow-out': [ @s_flow_line_prefix, n ]



  # XXX Can be removed
  # [068]
  # s-block-line-prefix(n) ::=
  #   s-indent(n)

  s_block_line_prefix: (n)->
    @rgx(s_indent_n(n))



  # [069]
  # s-flow-line-prefix(n) ::=
  #   s-indent(n)
  #   s-separate-in-line?

  s_flow_line_prefix: (n)->
    @all(
      @rgx(s_indent_n(n))
      @rep(0, 1, @rgx(re_s_separate_in_line))
    )



  # [070]
  # l-empty(n,c) ::=
  #   ( s-line-prefix(n,c) | s-indent(<n) )
  #   b-as-line-feed

  l_empty: (n, c)->
    @all(
      @any(
        [ @s_line_prefix, n, c ]
        [ @s_indent_lt, n ]
      )
      @rgx(re_b_as_line_feed)
    )



  # [072]
  # b-as-space ::=
  #   b-break

  re_b_as_space = re_b_break



  # [073]
  # b-l-folded(n,c) ::=
  #   b-l-trimmed(n,c) | b-as-space

  b_l_folded: (n, c)->
    @any(
      @all(
        @rgx(re_b_non_content)
        @rep(1, null, [ @l_empty, n, c ])
      )
      @rgx(re_b_as_space)
    )



  # [074]
  # s-flow-folded(n) ::=
  #   s-separate-in-line?
  #   b-l-folded(n,flow-in)
  #   s-flow-line-prefix(n)

  s_flow_folded: (n)->
    @all(
      @rep(0, 1, @rgx(re_s_separate_in_line))
      [ @b_l_folded, n, "flow-in" ]
      [ @s_flow_line_prefix, n ]
    )



  # [075]
  # c-nb-comment-text ::=
  #   '#' nb-char*

  [c_nb_comment_text] = r ///
    (?:
      \x23
      #{nb_char}*
    )
  ///u



  # [076]
  # b-comment ::=
  #   b-non-content | <end_of_file>

  [b_comment, re_b_comment] = r ///
    (?:
      #{b_non_content}
    | #{end_of_file}
    )
  ///



  # [077]
  # s-b-comment ::=
  #   ( s-separate-in-line
  #   c-nb-comment-text? )?
  #   b-comment

  s_b_comment: ->
    @all(
      @rep(0, 1,
        @all(
          @rgx(re_s_separate_in_line)
          @rgx(/// #{c_nb_comment_text}? ///yu, true)
        )
      )
      @rgx(re_b_comment, true)
    )



  # [078]
  # l-comment ::=
  #   s-separate-in-line c-nb-comment-text?
  #   b-comment

  l_comment: ->
    @all(
      @rgx(re_s_separate_in_line)
      @rgx(///
        #{c_nb_comment_text}*
        #{b_comment}
      ///yu)
    )



  # [079]
  # s-l-comments ::=
  #   ( s-b-comment | <start_of_line> )
  #   l-comment*

  s_l_comments: ->
    @all(
      @any(
        @s_b_comment
        @start_of_line
      )
      @rep(0, null, @l_comment)
    )



  # [080]
  # s-separate(n,c) ::=
  #   ( c = block-out => s-separate-lines(n) )
  #   ( c = block-in => s-separate-lines(n) )
  #   ( c = flow-out => s-separate-lines(n) )
  #   ( c = flow-in => s-separate-lines(n) )
  #   ( c = block-key => s-separate-in-line )
  #   ( c = flow-key => s-separate-in-line )

  s_separate: (n, c)->
    @case c,
      'block-in': [ @s_separate_lines, n ]
      'block-key': @rgx(re_s_separate_in_line)
      'block-out': [ @s_separate_lines, n ]
      'flow-in': [ @s_separate_lines, n ]
      'flow-key': @rgx(re_s_separate_in_line)
      'flow-out': [ @s_separate_lines, n ]



  # [081]
  # s-separate-lines(n) ::=
  #   ( s-l-comments
  #   s-flow-line-prefix(n) )
  #   | s-separate-in-line

  s_separate_lines: (n)->
    @any(
      @all(
        @s_l_comments
        [ @s_flow_line_prefix, n ]
      )
      @rgx(re_s_separate_in_line)
    )



  # [084]
  # ns-directive-name ::=
  #   ns-char+

  [ns_directive_name] = r ///
    #{ns_char}+
  ///u



  # [085]
  # ns-directive-parameter ::=
  #   ns-char+

  [ns_directive_parameter] = r ///
    #{ns_char}+
  ///u



  # [083]
  # ns-reserved-directive ::=
  #   ns-directive-name
  #   ( s-separate-in-line ns-directive-parameter )*

  [, re_ns_reserved_directive] = r ///
    #{ns_directive_name}
    (?:
      #{s_separate_in_line}
      #{ns_directive_parameter}
    )*
  ///u



  # [086]
  # ns-yaml-directive ::=
  #   'Y' 'A' 'M' 'L'
  #   s-separate-in-line ns-yaml-version

  ns_yaml_directive: ->
    @all(
      @rgx(///
        (?:
          Y A M L
          #{s_separate_in_line}
        )
      ///y)
      @ns_yaml_version
    )



  # [087]
  # ns-yaml-version ::=
  #   ns-dec-digit+ '.' ns-dec-digit+

  ns_yaml_version: ->
    @rgx(///
      #{ns_dec_digit}+
      \.
      #{ns_dec_digit}+
    ///y)



  # [088]
  # ns-tag-directive ::=
  #   'T' 'A' 'G'
  #   s-separate-in-line c-tag-handle
  #   s-separate-in-line ns-tag-prefix

  ns_tag_directive: ->
    @all(
      @rgx(///
        T A G
        #{s_separate_in_line}
      ///y)
      @c_tag_handle
      @rgx(re_s_separate_in_line)
      @ns_tag_prefix
    )



  # [090]
  # c-primary-tag-handle ::=
  #   '!'

  c_primary_tag_handle = "!"



  # [091]
  # c-secondary-tag-handle ::=
  #   '!' '!'

  c_secondary_tag_handle = "!!"



  # [092]
  # c-named-tag-handle ::=
  #   '!' ns-word-char+ '!'

  [c_named_tag_handle] = r ///
    !
    #{ns_word_char}+
    !
  ///



  # [089]
  # c-tag-handle ::=
  #   c-named-tag-handle
  #   | c-secondary-tag-handle
  #   | c-primary-tag-handle

  [c_tag_handle, re_c_tag_handle] = r ///
    (?:
      #{c_named_tag_handle}
    | #{c_secondary_tag_handle}
    | #{c_primary_tag_handle}
    )
  ///

  c_tag_handle: ->
    @rgx(re_c_tag_handle)



  # [094]
  # c-ns-local-tag-prefix ::=
  #   '!' ns-uri-char*

  [c_ns_local_tag_prefix] = r ///
    !
    #{ns_uri_char}*
  ///



  # [095]
  # ns-global-tag-prefix ::=
  #   ns-tag-char ns-uri-char*

  [ns_global_tag_prefix] = r ///
    #{ns_tag_char}
    #{ns_uri_char}*
  ///



  # [093]
  # ns-tag-prefix ::=
  #   c-ns-local-tag-prefix | ns-global-tag-prefix

  ns_tag_prefix: ->
    @rgx(///
      (?:
        #{c_ns_local_tag_prefix}
      | #{ns_global_tag_prefix}
      )
    ///y)



  # [096]
  # c-ns-properties(n,c) ::=
  #   ( c-ns-tag-property
  #   ( s-separate(n,c) c-ns-anchor-property )? )
  #   | ( c-ns-anchor-property
  #   ( s-separate(n,c) c-ns-tag-property )? )

  c_ns_properties: (n, c)->
    @any(
      @all(
        @c_ns_tag_property
        @rep(0, 1,
          @all(
            [ @s_separate, n, c ]
            @c_ns_anchor_property
          )
        )
      )
      @all(
        @c_ns_anchor_property
        @rep(0, 1,
          @all(
            [ @s_separate, n, c ]
            @c_ns_tag_property
          )
        )
      )
    )



  # [098]
  # c-verbatim-tag ::=
  #   '!' '<' ns-uri-char+ '>'

  [c_verbatim_tag] = r ///
      (?:
        !
        <
          #{ns_uri_char}+
        >
      )
  ///



  # [099]
  # c-ns-shorthand-tag ::=
  #   c-tag-handle ns-tag-char+

  [c_ns_shorthand_tag] = r ///
    (
      #{c_tag_handle}
      #{ns_tag_char}+
    )
  ///



  # [100]
  # c-non-specific-tag ::=
  #   '!'

  c_non_specific_tag = "!"



  # [097]
  # c-ns-tag-property ::=
  #   c-verbatim-tag
  #   | c-ns-shorthand-tag
  #   | c-non-specific-tag

  c_ns_tag_property: ->
    @rgx(///
      (?:
        #{c_verbatim_tag}
      | #{c_ns_shorthand_tag}
      | #{c_non_specific_tag}
      )
    ///y)



  # [102]
  # ns-anchor-char ::=
  #   ns-char - c-flow-indicator

  [ns_anchor_char] = r ///
    (?:
      (?!
        #{c_flow_indicator}
      )
      #{ns_char}
    )+
  ///u



  # [103]
  # ns-anchor-name ::=
  #   ns-anchor-char+

  [ns_anchor_name] = r ///
    (?:
      #{ns_anchor_char}
    )+
  ///u



  # [101]
  # c-ns-anchor-property ::=
  #   '&' ns-anchor-name

  c_ns_anchor_property: ->
    @rgx(///
      &
      #{ns_anchor_name}
    ///yu)



  # [104]
  # c-ns-alias-node ::=
  #   '*' ns-anchor-name

  c_ns_alias_node: ->
    @rgx(///
      \*
      #{ns_anchor_name}
    ///yu)



  # [106]
  # e-node ::=
  #   e-scalar

  e_node: ->
    @empty



  # [107]
  # nb-double-char ::=
  #   c-ns-esc-char | ( nb-json - '\' - '"' )

  [nb_double_char] = r ///
    (?:
      #{c_ns_esc_char}
    |
      (?! [ \\ " ])
      #{nb_json}
    )
  ///



  # [108]
  # ns-double-char ::=
  #   nb-double-char - s-white

  [ns_double_char, re_ns_double_char] = r ///
    (?! #{s_white})
    #{nb_double_char}
  ///



  # [109]
  # c-double-quoted(n,c) ::=
  #   '"' nb-double-text(n,c)
  #   '"'

  c_double_quoted: (n, c)->
    @all(
      @chr('"')
      [ @nb_double_text, n, c ]
      @chr('"')
    )



  # [110]
  # nb-double-text(n,c) ::=
  #   ( c = flow-out => nb-double-multi-line(n) )
  #   ( c = flow-in => nb-double-multi-line(n) )
  #   ( c = block-key => nb-double-one-line )
  #   ( c = flow-key => nb-double-one-line )

  nb_double_text: (n, c)->
    @case c,
      'block-key': @rgx(re_nb_double_one_line)
      'flow-in': [ @nb_double_multi_line, n ]
      'flow-key': @rgx(re_nb_double_one_line)
      'flow-out': [ @nb_double_multi_line, n ]



  # [111]
  # nb-double-one-line ::=
  #   nb-double-char*

  [, re_nb_double_one_line] = r ///
    #{nb_double_char}*
  ///



  # [112]
  # s-double-escaped(n) ::=
  #   s-white* '\'
  #   b-non-content
  #   l-empty(n,flow-in)* s-flow-line-prefix(n)

  s_double_escaped: (n)->
    @all(
      @rgx(///
        #{s_white}*
        \\
        #{b_non_content}
      ///y)
      @rep2(0, null, [ @l_empty, n, "flow-in" ])
      [ @s_flow_line_prefix, n ]
    )



  # [114]
  # nb-ns-double-in-line ::=
  #   ( s-white* ns-double-char )*

  [, re_nb_ns_double_in_line] = r ///
    (?:
      #{s_white}*
      #{ns_double_char}
    )*
  ///



  # [115]
  # s-double-next-line(n) ::=
  #   s-double-break(n)
  #   ( ns-double-char nb-ns-double-in-line
  #   ( s-double-next-line(n) | s-white* ) )?

  s_double_next_line: (n)->
    @all(
      @any(
        [ @s_double_escaped, n ]
        [ @s_flow_folded, n ]
      )
      @rep(0, 1,
        @all(
          @rgx(re_ns_double_char)
          @rgx(re_nb_ns_double_in_line)
          @any(
            [ @s_double_next_line, n ]
            @rgx("#{s_white}*")
          )
        )
      )
    )



  # [116]
  # nb-double-multi-line(n) ::=
  #   nb-ns-double-in-line
  #   ( s-double-next-line(n) | s-white* )

  nb_double_multi_line: (n)->
    @all(
      @rgx(re_nb_ns_double_in_line)
      @any(
        [ @s_double_next_line, n ]
        @rgx("#{s_white}*")
      )
    )



  # [117]
  # c-quoted-quote ::=
  #   ''' '''

  [c_quoted_quote] = r ///
    '
    '
  ///



  # [118]
  # nb-single-char ::=
  #   c-quoted-quote | ( nb-json - ''' )

  [nb_single_char] = r ///
    (?:
      #{c_quoted_quote}
    | (?:
        (?! ')
        #{nb_json}
      )
    )
  ///



  # [119]
  # ns-single-char ::=
  #   nb-single-char - s-white

  [ns_single_char] = r ///
    (?:
      (?! #{s_white})
      #{nb_single_char}
    )
  ///



  # [120]
  # c-single-quoted(n,c) ::=
  #   ''' nb-single-text(n,c)
  #   '''

  c_single_quoted: (n, c)->
    @all(
      @chr("'")
      [ @nb_single_text, n, c ]
      @chr("'")
    )



  # [121]
  # nb-single-text(n,c) ::=
  #   ( c = flow-out => nb-single-multi-line(n) )
  #   ( c = flow-in => nb-single-multi-line(n) )
  #   ( c = block-key => nb-single-one-line )
  #   ( c = flow-key => nb-single-one-line )

  nb_single_text: (n, c)->
    @case c,
      'block-key': @rgx(re_nb_single_one_line)
      'flow-in': [ @nb_single_multi_line, n ]
      'flow-key': @rgx(re_nb_single_one_line)
      'flow-out': [ @nb_single_multi_line, n ]



  # [122]
  # nb-single-one-line ::=
  #   nb-single-char*

  [, re_nb_single_one_line] = r ///
    #{nb_single_char}*
  ///



  # [123]
  # nb-ns-single-in-line ::=
  #   ( s-white* ns-single-char )*

  [nb_ns_single_in_line, re_nb_ns_single_in_line] = r ///
    (?:
      #{s_white}*
      #{ns_single_char}
    )*
  ///



  # [124]
  # s-single-next-line(n) ::=
  #   s-flow-folded(n)
  #   ( ns-single-char nb-ns-single-in-line
  #   ( s-single-next-line(n) | s-white* ) )?

  [, re_s_single_next_line] = r ///
    #{ns_single_char}
    #{nb_ns_single_in_line}
  ///

  s_single_next_line: (n)->
    @all(
      [ @s_flow_folded, n ]
      @rep(0, 1,
        @all(
          @rgx(re_s_single_next_line)
          @any(
            [ @s_single_next_line, n ]
            @rgx("#{s_white}*")
          )
        )
      )
    )



  # [125]
  # nb-single-multi-line(n) ::=
  #   nb-ns-single-in-line
  #   ( s-single-next-line(n) | s-white* )

  nb_single_multi_line: (n)->
    @all(
      @rgx(re_nb_ns_single_in_line)
      @any(
        [ @s_single_next_line, n ]
        @rgx("#{s_white}*")
      )
    )



  # [126]
  # ns-plain-first(c) ::=
  #   ( ns-char - c-indicator )
  #   | ( ( '?' | ':' | '-' )
  #   <followed_by_an_ns-plain-safe(c)> )

  ns_plain_first: (c)->
    @any(
      @rgx(///
        (?! #{c_indicator})
        #{ns_char}
      ///yu)
      @all(
        @rgx(///
          [
            ?
            :
            -
          ]
        ///y)
        @chk('=', [ @ns_plain_safe, c ])
      )
    )



  # [127]
  # ns-plain-safe(c) ::=
  #   ( c = flow-out => ns-plain-safe-out )
  #   ( c = flow-in => ns-plain-safe-in )
  #   ( c = block-key => ns-plain-safe-out )
  #   ( c = flow-key => ns-plain-safe-in )

  ns_plain_safe: (c)->
    @case c,
      'block-key': @rgx(re_ns_plain_safe_out)
      'flow-in': @rgx(re_ns_plain_safe_in)
      'flow-key': @rgx(re_ns_plain_safe_in)
      'flow-out': @rgx(re_ns_plain_safe_out)



  # [128]
  # ns-plain-safe-out ::=
  #   ns-char

  [, re_ns_plain_safe_out] = r ///
    (?: #{ns_char} )
  ///u



  # [129]
  # ns-plain-safe-in ::=
  #   ns-char - c-flow-indicator

  [, re_ns_plain_safe_in] = r ///
    (?:
      (?!
        #{c_flow_indicator}
      )
      #{ns_char}
    )
  ///u



  # [130]
  # ns-plain-char(c) ::=
  #   ( ns-plain-safe(c) - ':' - '#' )
  #   | ( <an_ns-char_preceding> '#' )
  #   | ( ':' <followed_by_an_ns-plain-safe(c)> )

  ns_plain_char: (c)->
    @any(
      @but(
        [ @ns_plain_safe, c ]
        @chr(':')
        @chr('#')
      )
      @all(
        @chk('<=', @rgx(re_ns_char))
        @chr('#')
      )
      @all(
        @chr(':')
        @chk('=', [ @ns_plain_safe, c ])
      )
    )



  # [131]
  # ns-plain(n,c) ::=
  #   ( c = flow-out => ns-plain-multi-line(n,c) )
  #   ( c = flow-in => ns-plain-multi-line(n,c) )
  #   ( c = block-key => ns-plain-one-line(c) )
  #   ( c = flow-key => ns-plain-one-line(c) )

  ns_plain: (n, c)->
    @case c,
      'block-key': [ @ns_plain_one_line, c ]
      'flow-in': [ @ns_plain_multi_line, n, c ]
      'flow-key': [ @ns_plain_one_line, c ]
      'flow-out': [ @ns_plain_multi_line, n, c ]



  # [132]
  # nb-ns-plain-in-line(c) ::=
  #   ( s-white*
  #   ns-plain-char(c) )*

  nb_ns_plain_in_line: (c)->
    @rep(0, null,
      @all(
        @rgx("#{s_white}*")
        [ @ns_plain_char, c ]
      )
    )



  # [133]
  # ns-plain-one-line(c) ::=
  #   ns-plain-first(c)
  #   nb-ns-plain-in-line(c)

  ns_plain_one_line: (c)->
    @all(
      [ @ns_plain_first, c ]
      [ @nb_ns_plain_in_line, c ]
    )



  # [134]
  # s-ns-plain-next-line(n,c) ::=
  #   s-flow-folded(n)
  #   ns-plain-char(c) nb-ns-plain-in-line(c)

  s_ns_plain_next_line: (n, c)->
    @all(
      [ @s_flow_folded, n ]
      [ @ns_plain_char, c ]
      [ @nb_ns_plain_in_line, c ]
    )



  # [135]
  # ns-plain-multi-line(n,c) ::=
  #   ns-plain-one-line(c)
  #   s-ns-plain-next-line(n,c)*

  ns_plain_multi_line: (n, c)->
    @all(
      [ @ns_plain_one_line, c ]
      @rep(0, null, [ @s_ns_plain_next_line, n, c ])
    )



  # [136]
  # in-flow(c) ::=
  #   ( c = flow-out => flow-in )
  #   ( c = flow-in => flow-in )
  #   ( c = block-key => flow-key )
  #   ( c = flow-key => flow-key )

  in_flow: (c)->
    @flip c,
      'block-key': "flow-key"
      'flow-in': "flow-in"
      'flow-key': "flow-key"
      'flow-out': "flow-in"



  # [137]
  # c-flow-sequence(n,c) ::=
  #   '[' s-separate(n,c)?
  #   ns-s-flow-seq-entries(n,in-flow(c))? ']'

  c_flow_sequence: (n, c)->
    @all(
      @chr('[')
      @rep(0, 1, [ @s_separate, n, c ])
      @rep2(0, 1, [ @ns_s_flow_seq_entries, n, [ @in_flow, c ] ])
      @chr(']')
    )



  # [138]
  # ns-s-flow-seq-entries(n,c) ::=
  #   ns-flow-seq-entry(n,c)
  #   s-separate(n,c)?
  #   ( ',' s-separate(n,c)?
  #   ns-s-flow-seq-entries(n,c)? )?

  ns_s_flow_seq_entries: (n, c)->
    @all(
      [ @ns_flow_seq_entry, n, c ]
      @rep(0, 1, [ @s_separate, n, c ])
      @rep2(0, 1,
        @all(
          @chr(',')
          @rep(0, 1, [ @s_separate, n, c ])
          @rep2(0, 1, [ @ns_s_flow_seq_entries, n, c ])
        )
      )
    )



  # [139]
  # ns-flow-seq-entry(n,c) ::=
  #   ns-flow-pair(n,c) | ns-flow-node(n,c)

  ns_flow_seq_entry: (n, c)->
    @any(
      [ @ns_flow_pair, n, c ]
      [ @ns_flow_node, n, c ]
    )



  # [140]
  # c-flow-mapping(n,c) ::=
  #   '{' s-separate(n,c)?
  #   ns-s-flow-map-entries(n,in-flow(c))? '}'

  c_flow_mapping: (n, c)->
    @all(
      @chr('{')
      @rep(0, 1, [ @s_separate, n, c ])
      @rep2(0, 1, [ @ns_s_flow_map_entries, n, [ @in_flow, c ] ])
      @chr('}')
    )



  # [141]
  # ns-s-flow-map-entries(n,c) ::=
  #   ns-flow-map-entry(n,c)
  #   s-separate(n,c)?
  #   ( ',' s-separate(n,c)?
  #   ns-s-flow-map-entries(n,c)? )?

  ns_s_flow_map_entries: (n, c)->
    @all(
      [ @ns_flow_map_entry, n, c ]
      @rep(0, 1, [ @s_separate, n, c ])
      @rep2(0, 1,
        @all(
          @chr(',')
          @rep(0, 1, [ @s_separate, n, c ])
          @rep2(0, 1, [ @ns_s_flow_map_entries, n, c ])
        )
      )
    )



  # [142]
  # ns-flow-map-entry(n,c) ::=
  #   ( '?' s-separate(n,c)
  #   ns-flow-map-explicit-entry(n,c) )
  #   | ns-flow-map-implicit-entry(n,c)

  ns_flow_map_entry: (n, c)->
    @any(
      @all(
        @rgx(///
          \?
          #{ws_lookahead}
        ///y)
        [ @s_separate, n, c ]
        [ @ns_flow_map_explicit_entry, n, c ]
      )
      [ @ns_flow_map_implicit_entry, n, c ]
    )



  # [143]
  # ns-flow-map-explicit-entry(n,c) ::=
  #   ns-flow-map-implicit-entry(n,c)
  #   | ( e-node
  #   e-node )

  ns_flow_map_explicit_entry: (n, c)->
    @any(
      [ @ns_flow_map_implicit_entry, n, c ]
      @all(
        @e_node
        @e_node
      )
    )



  # [144]
  # ns-flow-map-implicit-entry(n,c) ::=
  #   ns-flow-map-yaml-key-entry(n,c)
  #   | c-ns-flow-map-empty-key-entry(n,c)
  #   | c-ns-flow-map-json-key-entry(n,c)

  ns_flow_map_implicit_entry: (n, c)->
    @any(
      [ @ns_flow_map_yaml_key_entry, n, c ]
      [ @c_ns_flow_map_empty_key_entry, n, c ]
      [ @c_ns_flow_map_json_key_entry, n, c ]
    )



  # [145]
  # ns-flow-map-yaml-key-entry(n,c) ::=
  #   ns-flow-yaml-node(n,c)
  #   ( ( s-separate(n,c)?
  #   c-ns-flow-map-separate-value(n,c) )
  #   | e-node )

  ns_flow_map_yaml_key_entry: (n, c)->
    @all(
      [ @ns_flow_yaml_node, n, c ]
      @any(
        @all(
          @rep(0, 1, [ @s_separate, n, c ])
          [ @c_ns_flow_map_separate_value, n, c ]
        )
        @e_node
      )
    )



  # [146]
  # c-ns-flow-map-empty-key-entry(n,c) ::=
  #   e-node
  #   c-ns-flow-map-separate-value(n,c)

  c_ns_flow_map_empty_key_entry: (n, c)->
    @all(
      @e_node
      [ @c_ns_flow_map_separate_value, n, c ]
    )



  # [147]
  # c-ns-flow-map-separate-value(n,c) ::=
  #   ':' <not_followed_by_an_ns-plain-safe(c)>
  #   ( ( s-separate(n,c) ns-flow-node(n,c) )
  #   | e-node )

  c_ns_flow_map_separate_value: (n, c)->
    @all(
      @chr(':')
      @chk('!', [ @ns_plain_safe, c ])
      @any(
        @all(
          [ @s_separate, n, c ]
          [ @ns_flow_node, n, c ]
        )
        @e_node
      )
    )



  # [148]
  # c-ns-flow-map-json-key-entry(n,c) ::=
  #   c-flow-json-node(n,c)
  #   ( ( s-separate(n,c)?
  #   c-ns-flow-map-adjacent-value(n,c) )
  #   | e-node )

  c_ns_flow_map_json_key_entry: (n, c)->
    @all(
      [ @c_flow_json_node, n, c ]
      @any(
        @all(
          @rep(0, 1, [ @s_separate, n, c ])
          [ @c_ns_flow_map_adjacent_value, n, c ]
        )
        @e_node
      )
    )



  # [149]
  # c-ns-flow-map-adjacent-value(n,c) ::=
  #   ':' ( (
  #   s-separate(n,c)?
  #   ns-flow-node(n,c) )
  #   | e-node )

  c_ns_flow_map_adjacent_value: (n, c)->
    @all(
      @chr(':')
      @any(
        @all(
          @rep(0, 1, [ @s_separate, n, c ])
          [ @ns_flow_node, n, c ]
        )
        @e_node
      )
    )



  # [150]
  # ns-flow-pair(n,c) ::=
  #   ( '?' s-separate(n,c)
  #   ns-flow-map-explicit-entry(n,c) )
  #   | ns-flow-pair-entry(n,c)

  ns_flow_pair: (n, c)->
    @any(
      @all(
        @rgx(///
          \?
          #{ws_lookahead}
        ///)
        [ @s_separate, n, c ]
        [ @ns_flow_map_explicit_entry, n, c ]
      )
      [ @ns_flow_pair_entry, n, c ]
    )



  # [151]
  # ns-flow-pair-entry(n,c) ::=
  #   ns-flow-pair-yaml-key-entry(n,c)
  #   | c-ns-flow-map-empty-key-entry(n,c)
  #   | c-ns-flow-pair-json-key-entry(n,c)

  ns_flow_pair_entry: (n, c)->
    @any(
      [ @ns_flow_pair_yaml_key_entry, n, c ]
      [ @c_ns_flow_map_empty_key_entry, n, c ]
      [ @c_ns_flow_pair_json_key_entry, n, c ]
    )



  # [152]
  # ns-flow-pair-yaml-key-entry(n,c) ::=
  #   ns-s-implicit-yaml-key(flow-key)
  #   c-ns-flow-map-separate-value(n,c)

  ns_flow_pair_yaml_key_entry: (n, c)->
    @all(
      [ @ns_s_implicit_yaml_key, "flow-key" ]
      [ @c_ns_flow_map_separate_value, n, c ]
    )



  # [153]
  # c-ns-flow-pair-json-key-entry(n,c) ::=
  #   c-s-implicit-json-key(flow-key)
  #   c-ns-flow-map-adjacent-value(n,c)

  c_ns_flow_pair_json_key_entry: (n, c)->
    @all(
      [ @c_s_implicit_json_key, "flow-key" ]
      [ @c_ns_flow_map_adjacent_value, n, c ]
    )



  # [154]
  # ns-s-implicit-yaml-key(c) ::=
  #   ns-flow-yaml-node(n/a,c)
  #   s-separate-in-line?
  #   <at_most_1024_characters_altogether>

  ns_s_implicit_yaml_key: (c)->
    @all(
      @max(1024)
      [ @ns_flow_yaml_node, null, c ]
      @rep(0, 1, @rgx(re_s_separate_in_line))
    )



  # [155]
  # c-s-implicit-json-key(c) ::=
  #   c-flow-json-node(n/a,c)
  #   s-separate-in-line?
  #   <at_most_1024_characters_altogether>

  c_s_implicit_json_key: (c)->
    @all(
      @max(1024)
      [ @c_flow_json_node, null, c ]
      @rep(0, 1, @rgx(re_s_separate_in_line))
    )



  # [156]
  # ns-flow-yaml-content(n,c) ::=
  #   ns-plain(n,c)

  ns_flow_yaml_content: (n, c)->
    [ @ns_plain, n, c ]



  # [157]
  # c-flow-json-content(n,c) ::=
  #   c-flow-sequence(n,c) | c-flow-mapping(n,c)
  #   | c-single-quoted(n,c) | c-double-quoted(n,c)

  c_flow_json_content: (n, c)->
    @any(
      [ @c_flow_sequence, n, c ]
      [ @c_flow_mapping, n, c ]
      [ @c_single_quoted, n, c ]
      [ @c_double_quoted, n, c ]
    )



  # [158]
  # ns-flow-content(n,c) ::=
  #   ns-flow-yaml-content(n,c) | c-flow-json-content(n,c)

  ns_flow_content: (n, c)->
    @any(
      [ @ns_flow_yaml_content, n, c ]
      [ @c_flow_json_content, n, c ]
    )



  # [159]
  # ns-flow-yaml-node(n,c) ::=
  #   c-ns-alias-node
  #   | ns-flow-yaml-content(n,c)
  #   | ( c-ns-properties(n,c)
  #   ( ( s-separate(n,c)
  #   ns-flow-yaml-content(n,c) )
  #   | e-scalar ) )

  ns_flow_yaml_node: (n, c)->
    @any(
      @c_ns_alias_node
      [ @ns_flow_yaml_content, n, c ]
      @all(
        [ @c_ns_properties, n, c ]
        @any(
          @all(
            [ @s_separate, n, c ]
            [ @ns_flow_content, n, c ]
          )
          @e_node
        )
      )
    )



  # [160]
  # c-flow-json-node(n,c) ::=
  #   ( c-ns-properties(n,c)
  #   s-separate(n,c) )?
  #   c-flow-json-content(n,c)

  c_flow_json_node: (n, c)->
    @all(
      @rep(0, 1,
        @all(
          [ @c_ns_properties, n, c ]
          [ @s_separate, n, c ]
        )
      )
      [ @c_flow_json_content, n, c ]
    )



  # [161]
  # ns-flow-node(n,c) ::=
  #   c-ns-alias-node
  #   | ns-flow-content(n,c)
  #   | ( c-ns-properties(n,c)
  #   ( ( s-separate(n,c)
  #   ns-flow-content(n,c) )
  #   | e-scalar ) )

  ns_flow_node: (n, c)->
    @any(
      @c_ns_alias_node
      [ @ns_flow_content, n, c ]
      @all(
        [ @c_ns_properties, n, c ]
        @any(
          @all(
            [ @s_separate, n, c ]
            [ @ns_flow_content, n, c ]
          )
          @e_node
        )
      )
    )



  # [162]
  # c-b-block-header(m,t) ::=
  #   ( ( c-indentation-indicator(m)
  #   c-chomping-indicator(t) )
  #   | ( c-chomping-indicator(t)
  #   c-indentation-indicator(m) ) )
  #   s-b-comment

  c_b_block_header: (n)->
    @all(
      @any(
        @all(
          [ @c_indentation_indicator, n ]
          @c_chomping_indicator
          @rgx(ws_lookahead)
        )
        @all(
          @c_chomping_indicator
          [ @c_indentation_indicator, n ]
          @rgx(ws_lookahead)
        )
      )
      @s_b_comment
    )



  # [163]
  # c-indentation-indicator(m) ::=
  #   ( ns-dec-digit => m = ns-dec-digit - x:30 )
  #   ( <empty> => m = auto-detect() )

  c_indentation_indicator: (n)->
    @any(
      @if(@rng("\x31", "\x39"), @set('m', @ord(@match)))
      @if(@empty, @set('m', [ @auto_detect, n ]))
    )



  # [164]
  # c-chomping-indicator(t) ::=
  #   ( '-' => t = strip )
  #   ( '+' => t = keep )
  #   ( <empty> => t = clip )

  c_chomping_indicator: ->
    @any(
      @if(@chr('-'), @set('t', "strip"))
      @if(@chr('+'), @set('t', "keep"))
      @if(@empty, @set('t', "clip"))
    )



  # [165]
  # b-chomped-last(t) ::=
  #   ( t = strip => b-non-content | <end_of_file> )
  #   ( t = clip => b-as-line-feed | <end_of_file> )
  #   ( t = keep => b-as-line-feed | <end_of_file> )

  b_chomped_last: (t)->
    @case t,
      'clip': @any( @rgx(re_b_as_line_feed), @end_of_stream )
      'keep': @any( @rgx(re_b_as_line_feed), @end_of_stream )
      'strip': @any( @rgx(re_b_non_content), @end_of_stream )



  # [166]
  # l-chomped-empty(n,t) ::=
  #   ( t = strip => l-strip-empty(n) )
  #   ( t = clip => l-strip-empty(n) )
  #   ( t = keep => l-keep-empty(n) )

  l_chomped_empty: (n, t)->
    @case t,
      'clip': [ @l_strip_empty, n ]
      'keep': [ @l_keep_empty, n ]
      'strip': [ @l_strip_empty, n ]



  # [167]
  # l-strip-empty(n) ::=
  #   ( s-indent(<=n) b-non-content )*
  #   l-trail-comments(n)?

  l_strip_empty: (n)->
    @all(
      @rep(0, null,
        @all(
          [ @s_indent_le, n ]
          @rgx(re_b_non_content)
        )
      )
      @rep2(0, 1, [ @l_trail_comments, n ])
    )



  # [168]
  # l-keep-empty(n) ::=
  #   l-empty(n,block-in)*
  #   l-trail-comments(n)?

  l_keep_empty: (n)->
    @all(
      @rep(0, null, [ @l_empty, n, "block-in" ])
      @rep2(0, 1, [ @l_trail_comments, n ])
    )



  # [169]
  # l-trail-comments(n) ::=
  #   s-indent(<n)
  #   c-nb-comment-text b-comment
  #   l-comment*

  [, re_l_trail_comments] = r ///
    #{c_nb_comment_text}
    #{b_comment}
  ///u

  l_trail_comments: (n)->
    @all(
      [ @s_indent_lt, n ]
      @rgx(re_l_trail_comments)
      @rep(0, null, @l_comment)
    )



  # [170]
  # c-l+literal(n) ::=
  #   '|' c-b-block-header(m,t)
  #   l-literal-content(n+m,t)

  c_l_literal: (n)->
    @all(
      @chr('|')
      [ @c_b_block_header, n ]
      [ @l_literal_content, @add(n, @m()), @t() ]
    )



  # [171]
  # l-nb-literal-text(n) ::=
  #   l-empty(n,block-in)*
  #   s-indent(n) nb-char+

  l_nb_literal_text: (n)->
    @all(
      @rep(0, null, [ @l_empty, n, "block-in" ])
      @rgx(s_indent_n(n))
      @rep2(1, null, @rgx(re_nb_char))
    )



  # [172]
  # b-nb-literal-next(n) ::=
  #   b-as-line-feed
  #   l-nb-literal-text(n)

  b_nb_literal_next: (n)->
    @all(
      @rgx(re_b_as_line_feed)
      [ @l_nb_literal_text, n ]
    )



  # [173]
  # l-literal-content(n,t) ::=
  #   ( l-nb-literal-text(n)
  #   b-nb-literal-next(n)*
  #   b-chomped-last(t) )?
  #   l-chomped-empty(n,t)

  l_literal_content: (n, t)->
    @all(
      @rep(0, 1,
        @all(
          [ @l_nb_literal_text, n ]
          @rep(0, null, [ @b_nb_literal_next, n ])
          [ @b_chomped_last, t ]
        )
      )
      [ @l_chomped_empty, n, t ]
    )



  # [174]
  # c-l+folded(n) ::=
  #   '>' c-b-block-header(m,t)
  #   l-folded-content(n+m,t)

  c_l_folded: (n)->
    @all(
      @chr('>')
      [ @c_b_block_header, n ]
      [ @l_folded_content, @add(n, @m()), @t() ]
    )



  # [175]
  # s-nb-folded-text(n) ::=
  #   s-indent(n) ns-char
  #   nb-char*

  # XXX Can't eliminate this yet for some reason.
  ns_char: ->
    @rgx(re_ns_char)

  s_nb_folded_text: (n)->
    @all(
      @rgx(s_indent_n(n))
      @ns_char                          # XXX only used here
      @rep(0, null, @rgx(re_nb_char))
    )



  # [176]
  # l-nb-folded-lines(n) ::=
  #   s-nb-folded-text(n)
  #   ( b-l-folded(n,block-in) s-nb-folded-text(n) )*

  l_nb_folded_lines: (n)->
    @all(
      [ @s_nb_folded_text, n ]
      @rep(0, null,
        @all(
          [ @b_l_folded, n, "block-in" ]
          [ @s_nb_folded_text, n ]
        )
      )
    )



  # [177]
  # s-nb-spaced-text(n) ::=
  #   s-indent(n) s-white
  #   nb-char*

  # XXX renaming this or eliminating it causes tests to fail. :\
  s_white: ->
    @rgx(///
      [
        #{s_space}
        \t
      ]
    ///y)

  s_nb_spaced_text: (n)->
    @all(
      @rgx(s_indent_n(n))
      @s_white                          # XXX only used here
      @rep(0, null, @rgx(re_nb_char))
    )



  # [178]
  # b-l-spaced(n) ::=
  #   b-as-line-feed
  #   l-empty(n,block-in)*

  b_l_spaced: (n)->
    @all(
      @rgx(re_b_as_line_feed)
      @rep(0, null, [ @l_empty, n, "block-in" ])
    )



  # [179]
  # l-nb-spaced-lines(n) ::=
  #   s-nb-spaced-text(n)
  #   ( b-l-spaced(n) s-nb-spaced-text(n) )*

  l_nb_spaced_lines: (n)->
    @all(
      [ @s_nb_spaced_text, n ]
      @rep(0, null,
        @all(
          [ @b_l_spaced, n ]
          [ @s_nb_spaced_text, n ]
        )
      )
    )



  # [180]
  # l-nb-same-lines(n) ::=
  #   l-empty(n,block-in)*
  #   ( l-nb-folded-lines(n) | l-nb-spaced-lines(n) )

  l_nb_same_lines: (n)->
    @all(
      @rep(0, null, [ @l_empty, n, "block-in" ])
      @any(
        [ @l_nb_folded_lines, n ]
        [ @l_nb_spaced_lines, n ]
      )
    )



  # [181]
  # l-nb-diff-lines(n) ::=
  #   l-nb-same-lines(n)
  #   ( b-as-line-feed l-nb-same-lines(n) )*

  l_nb_diff_lines: (n)->
    @all(
      [ @l_nb_same_lines, n ]
      @rep(0, null,
        @all(
          @rgx(re_b_as_line_feed)
          [ @l_nb_same_lines, n ]
        )
      )
    )



  # [182]
  # l-folded-content(n,t) ::=
  #   ( l-nb-diff-lines(n)
  #   b-chomped-last(t) )?
  #   l-chomped-empty(n,t)

  l_folded_content: (n, t)->
    @all(
      @rep(0, 1,
        @all(
          [ @l_nb_diff_lines, n ]
          [ @b_chomped_last, t ]
        )
      )
      [ @l_chomped_empty, n, t ]
    )

  func() for func in init
