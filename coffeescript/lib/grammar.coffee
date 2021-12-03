###
This grammar class was generated from https://yaml.org/spec/1.2/spec.html
###

global.Grammar = class Grammar

  TOP: -> @l_yaml_stream

  r2s = (re)->
    if not re instanceof RegExp
      throw "Not a regex #{re}"
    String(re)[1..-4]

  r2c = (re)->
    if not re instanceof RegExp
      throw "Not a regex #{re}"
    String(re)[2..-5]



  # [001]
  # c-printable ::=
  #   x:9 | x:A | x:D | [x:20-x:7E]
  #   | x:85 | [x:A0-x:D7FF] | [x:E000-x:FFFD]
  #   | [x:10000-x:10FFFF]

  c_printable = r2s ///
    [
      \u{09}
      \u{0A}
      \u{0D}
      \u{20}-\u{7E}
      \u{85}
      \u{A0}-\u{D7FF}
      \u{E000}-\u{FFFD}
      \u{10000}-\u{10FFFF}
    ]
  ///yu



  # [002]
  # nb-json ::=
  #   x:9 | [x:20-x:10FFFF]

  nb_json = r2s ///
    [
      \u{09}
      \u{20}-\u{ffff}
      # \u{20}-\u{10FFFF}
    ]
  ///yu



  # [003]
  # c-byte-order-mark ::=
  #   x:FEFF

  c_byte_order_mark = "\u{FEFF}"



  # [022]
  # c-indicator ::=
  #   '-' | '?' | ':' | ',' | '[' | ']' | '{' | '}'
  #   | '#' | '&' | '*' | '!' | '|' | '>' | ''' | '"'
  #   | '%' | '@' | '`'

  c_indicator = r2s ///
    [
       -  ?  :  ,
       [ \]  {  }
       &  *  !  \u{23}
       |  >  '  "
       %  @  `
    ]
  ///yu



  # [023]
  # c-flow-indicator ::=
  #   ',' | '[' | ']' | '{' | '}'

  c_flow_indicator = r2s ///
    [
      , [ \] { }
    ]
  ///yu



  # [024]
  # b-line-feed ::=
  #   x:A

  b_line_feed = "\u{0A}"



  # [025]
  # b-carriage-return ::=
  #   x:D

  b_carriage_return = "\u{0D}"



  # [026]
  # b-char ::=
  #   b-line-feed | b-carriage-return

  re_b_char = ///
    [ \u{0A} \u{0D} ]
  ///yu
  b_char = r2s re_b_char
  b_char_s = r2c re_b_char



  # [027]
  # nb-char ::=
  #   c-printable - b-char - c-byte-order-mark

  re_nb_char = ///
    (?:
      (?!
        [
          #{b_char_s}
          #{c_byte_order_mark}
        ]
      )
      #{c_printable}
    )
  ///yu
  nb_char = r2s re_nb_char

  nb_char: ->
    # debug_rule("nb_char")
    @rgx(re_nb_char)



  # [028]
  # b-break ::=
  #   ( b-carriage-return b-line-feed )
  #   | b-carriage-return
  #   | b-line-feed

  re_line_break = ///
    (?:
      #{b_carriage_return}
      #{b_line_feed}
    | #{b_carriage_return}
    | #{b_line_feed}
    )
  ///yu
  line_break = r2s re_line_break



  # [029]
  # b-as-line-feed ::=
  #   b-break

  b_as_line_feed: ->
    # debug_rule("b_as_line_feed")
    @rgx(re_line_break)



  # [031]
  # s-space ::=
  #   x:20

  s_space = "\u{20}"



  # [033]
  # s-white ::=
  #   s-space | s-tab

  re_s_white = ///
    [
      #{s_space}
      \t
    ]
  ///yu
  s_white = r2s re_s_white

  s_white: ->
    # debug_rule("s_white")
    @rgx(re_s_white)



  # [034]
  # ns-char ::=
  #   nb-char - s-white

  re_ns_char = ///
    (?:
      (?! #{s_white} )
      #{nb_char}
    )
  ///yu
  ns_char = r2s re_ns_char

  ns_char: ->
    # debug_rule("ns_char")
    @rgx(re_ns_char)



  # [035]
  # ns-dec-digit ::=
  #   [x:30-x:39]

  re_ns_dec_digit = ///
    [ 0 - 9 ]
  ///yu
  ns_dec_digit = r2s re_ns_dec_digit
  ns_dec_digit_s = r2c re_ns_dec_digit



  # [036]
  # ns-hex-digit ::=
  #   ns-dec-digit
  #   | [x:41-x:46] | [x:61-x:66]

  ns_hex_digit = r2s ///
    [
      #{ns_dec_digit_s}
      A-F
      a-f
    ]
  ///yu



  # [037]
  # ns-ascii-letter ::=
  #   [x:41-x:5A] | [x:61-x:7A]

  re_ns_ascii_letter = ///
    [
      \u{41}-\u{5A}
      \u{61}-\u{7A}
    ]
  ///yu
  ns_ascii_letter_s = r2c re_ns_ascii_letter



  # [038]
  # ns-word-char ::=
  #   ns-dec-digit | ns-ascii-letter | '-'

  re_ns_word_char = ///
    [ \- #{ns_dec_digit_s} #{ns_ascii_letter_s} ]
  ///yu
  ns_word_char = r2s re_ns_word_char
  ns_word_char_s = r2c re_ns_word_char



  # [039]
  # ns-uri-char ::=
  #   '%' ns-hex-digit ns-hex-digit | ns-word-char | '#'
  #   | ';' | '/' | '?' | ':' | '@' | '&' | '=' | '+' | '$' | ','
  #   | '_' | '.' | '!' | '~' | '*' | ''' | '(' | ')' | '[' | ']'

  ns_uri_char = r2s ///
    (?:
      % #{ns_hex_digit}{2}
    | [
        #{ns_word_char_s}
        \u{23} ; / ? : @ & = + $
        , _ . ! ~ * ' ( ) [ \]
      ]
    )
  ///yu



  # [040]
  # ns-tag-char ::=
  #   ns-uri-char - '!' - c-flow-indicator

  ns_tag_char = r2s ///
    (?:
      (?! ! | #{c_flow_indicator} )
      #{ns_uri_char}
    )
  ///yu



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

  c_ns_esc_char = r2s ///
    \\
    (?:
      [
        0 a b t
        \u{09} n v f r e
        \u{20} " / \\
        N _ L P
      ]
    | x #{ns_hex_digit}{2}
    | u #{ns_hex_digit}{4}
    | U #{ns_hex_digit}{8}
    )
  ///yu



  # [063]
  re_s_indent = /// #{s_space}* ///yu
  re_s_indent_n = (n)-> /// #{s_space}{#{n}} ///yu



  # [064]
  # s-indent(<n) ::=
  #   s-space{m} <where_m_<_n>

  s_indent_lt: (n)->
    # debug_rule("s_indent_lt",n)
    @all(
      @rgx(re_s_indent)
      @lt(@len(@match), n)
    )



  # [065]
  # s-indent(<=n) ::=
  #   s-space{m} <where_m_<=_n>

  s_indent_le: (n)->
    # debug_rule("s_indent_le",n)
    @all(
      @rgx(re_s_indent)
      @le(@len(@match), n)
    )



  # [066]
  # s-separate-in-line ::=
  #   s-white+ | <start_of_line>

  s_separate_spaces = r2s ///
    #{s_white}+
  ///yu

  s_separate_in_line: ->
    # debug_rule("s_separate_in_line")
    @any(
      @rgx(/// #{s_separate_spaces} ///yu)
      @start_of_line
    )



  # [067]
  # s-line-prefix(n,c) ::=
  #   ( c = block-out => s-block-line-prefix(n) )
  #   ( c = block-in => s-block-line-prefix(n) )
  #   ( c = flow-out => s-flow-line-prefix(n) )
  #   ( c = flow-in => s-flow-line-prefix(n) )

  s_line_prefix: (n, c)->
    # debug_rule("s_line_prefix",n,c)
    @case(
      c
      {
        'block-in': @rgx(re_s_indent_n(n))
        'block-out': @rgx(re_s_indent_n(n))
        'flow-in': [ @s_flow_line_prefix, n ]
        'flow-out': [ @s_flow_line_prefix, n ]
      }
    )



  # [069]
  # s-flow-line-prefix(n) ::=
  #   s-indent(n)
  #   s-separate-in-line?

  s_flow_line_prefix: (n)->
    # debug_rule("s_flow_line_prefix",n)
    @all(
      @rgx(re_s_indent_n(n))
      @rep(0, 1, @s_separate_in_line)
    )



  # [070]
  # l-empty(n,c) ::=
  #   ( s-line-prefix(n,c) | s-indent(<n) )
  #   b-as-line-feed

  l_empty: (n, c)->
    # debug_rule("l_empty",n,c)
    @all(
      @any(
        [ @s_line_prefix, n, c ]
        [ @s_indent_lt, n ]
      )
      @b_as_line_feed
    )



  # [071]
  # b-l-trimmed(n,c) ::=
  #   b-non-content l-empty(n,c)+

  b_l_trimmed: (n, c)->
    # debug_rule("b_l_trimmed",n,c)
    @all(
      @rgx(re_line_break)
      @rep(1, null, [ @l_empty, n, c ])
    )



  # [073]
  # b-l-folded(n,c) ::=
  #   b-l-trimmed(n,c) | b-as-space

  b_l_folded: (n, c)->
    # debug_rule("b_l_folded",n,c)
    @any(
      [ @b_l_trimmed, n, c ]
      @rgx(re_line_break)
    )



  # [074]
  # s-flow-folded(n) ::=
  #   s-separate-in-line?
  #   b-l-folded(n,flow-in)
  #   s-flow-line-prefix(n)

  s_flow_folded: (n)->
    # debug_rule("s_flow_folded",n)
    @all(
      @rep(0, 1, @s_separate_in_line)
      [ @b_l_folded, n, "flow-in" ]
      [ @s_flow_line_prefix, n ]
    )



  # [075]
  # c-nb-comment-text ::=
  #   '#' nb-char*

  c_nb_comment_text = r2s ///
    (?:
      \u{23}
      #{nb_char}*
    )
  ///yu



  # [076]
  # b-comment ::=
  #   b-non-content | <end_of_file>

  re_b_comment = ///
    (?:
      #{line_break}
    | $
    )
  ///yu
  b_comment = r2s re_b_comment



  # [077]
  # s-b-comment ::=
  #   ( s-separate-in-line
  #   c-nb-comment-text? )?
  #   b-comment

  s_b_comment: ->
    # debug_rule("s_b_comment")
    @all(
      @rep(0, 1
        @all(
          @s_separate_in_line
          @rgx2(/// #{c_nb_comment_text}? ///yu)
        ))
      @rgx2(re_b_comment)
    )



  # [078]
  # l-comment ::=
  #   s-separate-in-line c-nb-comment-text?
  #   b-comment

  l_comment: ->
    # debug_rule("l_comment")
    @all(
      @s_separate_in_line
      @rgx(/// #{c_nb_comment_text}* #{b_comment} ///yu)
    )



  # [079]
  # s-l-comments ::=
  #   ( s-b-comment | <start_of_line> )
  #   l-comment*

  s_l_comments: ->
    # debug_rule("s_l_comments")
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
    # debug_rule("s_separate",n,c)
    @case(
      c
      {
        'block-in': [ @s_separate_lines, n ]
        'block-key': @s_separate_in_line
        'block-out': [ @s_separate_lines, n ]
        'flow-in': [ @s_separate_lines, n ]
        'flow-key': @s_separate_in_line
        'flow-out': [ @s_separate_lines, n ]
      }
    )



  # [081]
  # s-separate-lines(n) ::=
  #   ( s-l-comments
  #   s-flow-line-prefix(n) )
  #   | s-separate-in-line

  s_separate_lines: (n)->
    # debug_rule("s_separate_lines",n)
    @any(
      @all(
        @s_l_comments
        [ @s_flow_line_prefix, n ]
      )
      @s_separate_in_line
    )



  # [082]
  # l-directive ::=
  #   '%'
  #   ( ns-yaml-directive
  #   | ns-tag-directive
  #   | ns-reserved-directive )
  #   s-l-comments

  l_directive: ->
    # debug_rule("l_directive")
    @all(
      @chr('%')
      @any(
        @ns_yaml_directive
        @ns_tag_directive
        @rgx(re_ns_reserved_directive)
      )
      @s_l_comments
    )



  # [084]
  # ns-directive-name ::=
  #   ns-char+

  ns_directive_name = r2s ///
    #{ns_char}+
  ///yu



  # [085]
  # ns-directive-parameter ::=
  #   ns-char+

  ns_directive_parameter = r2s ///
    #{ns_char}+
  ///yu



  # [083]
  # ns-reserved-directive ::=
  #   ns-directive-name
  #   ( s-separate-in-line ns-directive-parameter )*

  re_ns_reserved_directive = ///
    #{ns_directive_name}
    (?:
      #{s_separate_spaces}
      #{ns_directive_parameter}
    )*
  ///yu



  # [087]
  # ns-yaml-version ::=
  #   ns-dec-digit+ '.' ns-dec-digit+

  re_ns_yaml_version = ///
    #{ns_dec_digit}+
    \.
    #{ns_dec_digit}+
  ///yu

  ns_yaml_version: ->
    # debug_rule("ns_yaml_version")
    @rgx(re_ns_yaml_version)



  # [086]
  # ns-yaml-directive ::=
  #   'Y' 'A' 'M' 'L'
  #   s-separate-in-line ns-yaml-version

  re_ns_yaml_directive = ///
    (?:
      Y A M L
      #{s_separate_spaces}
    )
  ///yu

  ns_yaml_directive: ->
    # debug_rule("ns_yaml_directive")
    @all(
      @rgx(re_ns_yaml_directive)
      @ns_yaml_version
    )



  # [088]
  # ns-tag-directive ::=
  #   'T' 'A' 'G'
  #   s-separate-in-line c-tag-handle
  #   s-separate-in-line ns-tag-prefix

  ns_tag_directive: ->
    # debug_rule("ns_tag_directive")
    @all(
      @rgx(/// T A G #{s_separate_spaces} ///yu)
      @c_tag_handle
      @s_separate_in_line
      @ns_tag_prefix
    )



  # [090]
  # c-primary-tag-handle ::=
  #   '!'

  c_primary_tag_handle = r2s ///
    !
  ///yu



  # [091]
  # c-secondary-tag-handle ::=
  #   '!' '!'

  c_secondary_tag_handle = r2s ///
    !
    !
  ///yu



  # [092]
  # c-named-tag-handle ::=
  #   '!' ns-word-char+ '!'

  c_named_tag_handle = r2s ///
    !
    #{ns_word_char}+
    !
  ///yu



  # [089]
  # c-tag-handle ::=
  #   c-named-tag-handle
  #   | c-secondary-tag-handle
  #   | c-primary-tag-handle

  re_c_tag_handle = ///
    (?:
      #{c_named_tag_handle}
    | #{c_secondary_tag_handle}
    | #{c_primary_tag_handle}
    )
  ///yu
  c_tag_handle = r2s re_c_tag_handle

  c_tag_handle: ->
    # debug_rule("c_tag_handle")
    @rgx(re_c_tag_handle)



  # [094]
  # c-ns-local-tag-prefix ::=
  #   '!' ns-uri-char*

  c_ns_local_tag_prefix = r2s ///
    !
    #{ns_uri_char}*
  ///yu



  # [095]
  # ns-global-tag-prefix ::=
  #   ns-tag-char ns-uri-char*

  ns_global_tag_prefix = r2s ///
    #{ns_tag_char}
    #{ns_uri_char}*
  ///yu



  # [093]
  # ns-tag-prefix ::=
  #   c-ns-local-tag-prefix | ns-global-tag-prefix

  re_ns_tag_prefix = ///
    (?:
      #{c_ns_local_tag_prefix}
    | #{ns_global_tag_prefix}
    )
  ///yu

  ns_tag_prefix: ->
    # debug_rule("ns_tag_prefix")
    @rgx(re_ns_tag_prefix)



  # [096]
  # c-ns-properties(n,c) ::=
  #   ( c-ns-tag-property
  #   ( s-separate(n,c) c-ns-anchor-property )? )
  #   | ( c-ns-anchor-property
  #   ( s-separate(n,c) c-ns-tag-property )? )

  c_ns_properties: (n, c)->
    # debug_rule("c_ns_properties",n,c)
    @any(
      @all(
        @c_ns_tag_property
        @rep(0, 1
          @all(
            [ @s_separate, n, c ]
            @c_ns_anchor_property
          ))
      )
      @all(
        @c_ns_anchor_property
        @rep(0, 1
          @all(
            [ @s_separate, n, c ]
            @c_ns_tag_property
          ))
      )
    )



  # [097]
  # c-ns-tag-property ::=
  #   c-verbatim-tag
  #   | c-ns-shorthand-tag
  #   | c-non-specific-tag

  c_ns_tag_property: ->
    # debug_rule("c_ns_tag_property")
    @rgx(
      ///
        (?:
          (
            !
            <
              #{ns_uri_char}+
            >
          )
        |
          (
            #{c_tag_handle}
            #{ns_tag_char}+
          )
        |
          !
        )
      ///yu
    )



  # [103]
  # ns-anchor-name ::=
  #   ns-anchor-char+

  ns_anchor_name = r2s ///
    (?:
      (?! #{c_flow_indicator} )
      #{ns_char}
    )+
  ///yu



  # [101]
  # c-ns-anchor-property ::=
  #   '&' ns-anchor-name

  re_c_ns_anchor_property = ///
    &
    #{ns_anchor_name}
  ///yu

  c_ns_anchor_property: ->
    # debug_rule("c_ns_anchor_property")
    @rgx(re_c_ns_anchor_property)



  # [104]
  # c-ns-alias-node ::=
  #   '*' ns-anchor-name

  re_c_ns_alias_node = ///
    \* #{ns_anchor_name}
  ///yu

  c_ns_alias_node: ->
    # debug_rule("c_ns_alias_node")
    @rgx(re_c_ns_alias_node)



  # [105]
  # e-scalar ::=
  #   <empty>

  e_scalar: ->
    # debug_rule("e_scalar")
    @empty



  # [106]
  # e-node ::=
  #   e-scalar

  e_node: ->
    # debug_rule("e_node")
    @e_scalar



  # [107]
  # nb-double-char ::=
  #   c-ns-esc-char | ( nb-json - '\' - '"' )

  nb_double_char = r2s ///
    (?:
      #{c_ns_esc_char}
    |
      (?! [ \\ " ])
      #{nb_json}
    )
  ///yu



  # [108]
  # ns-double-char ::=
  #   nb-double-char - s-white

  re_ns_double_char = ///
    (?! #{s_white})
    #{nb_double_char}
  ///yu
  ns_double_char = r2s re_ns_double_char



  # [109]
  # c-double-quoted(n,c) ::=
  #   '"' nb-double-text(n,c)
  #   '"'

  c_double_quoted: (n, c)->
    # debug_rule("c_double_quoted",n,c)
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
    # debug_rule("nb_double_text",n,c)
    @case(
      c
      {
        'block-key': @rgx(re_nb_double_one_line)
        'flow-in': [ @nb_double_multi_line, n ]
        'flow-key': @rgx(re_nb_double_one_line)
        'flow-out': [ @nb_double_multi_line, n ]
      }
    )



  # [111]
  # nb-double-one-line ::=
  #   nb-double-char*

  re_nb_double_one_line = ///
    #{nb_double_char}*
  ///yu



  # [112]
  # s-double-escaped(n) ::=
  #   s-white* '\'
  #   b-non-content
  #   l-empty(n,flow-in)* s-flow-line-prefix(n)

  s_double_escaped: (n)->
    # debug_rule("s_double_escaped",n)
    @all(
      @rep(0, null, @s_white)
      @chr("\\")
      @rgx(re_line_break)
      @rep2(0, null, [ @l_empty, n, "flow-in" ])
      [ @s_flow_line_prefix, n ]
    )



  # [113]
  # s-double-break(n) ::=
  #   s-double-escaped(n) | s-flow-folded(n)

  s_double_break: (n)->
    # debug_rule("s_double_break",n)
    @any(
      [ @s_double_escaped, n ]
      [ @s_flow_folded, n ]
    )



  # [114]
  # nb-ns-double-in-line ::=
  #   ( s-white* ns-double-char )*

  re_nb_ns_double_in_line = ///
    (?:
      #{s_white}*
      #{ns_double_char}
    )*
  ///yu



  # [115]
  # s-double-next-line(n) ::=
  #   s-double-break(n)
  #   ( ns-double-char nb-ns-double-in-line
  #   ( s-double-next-line(n) | s-white* ) )?

  s_double_next_line: (n)->
    # debug_rule("s_double_next_line",n)
    @all(
      [ @s_double_break, n ]
      @rep(0, 1
        @all(
          @rgx(re_ns_double_char)
          @rgx(re_nb_ns_double_in_line)
          @any(
            [ @s_double_next_line, n ]
            @rep(0, null, @s_white)
          )
        ))
    )



  # [116]
  # nb-double-multi-line(n) ::=
  #   nb-ns-double-in-line
  #   ( s-double-next-line(n) | s-white* )

  nb_double_multi_line: (n)->
    # debug_rule("nb_double_multi_line",n)
    @all(
      @rgx(re_nb_ns_double_in_line)
      @any(
        [ @s_double_next_line, n ]
        @rep(0, null, @s_white)
      )
    )



  # [117]
  # c-quoted-quote ::=
  #   ''' '''

  c_quoted_quote = r2s /// ' ' ///yu



  # [118]
  # nb-single-char ::=
  #   c-quoted-quote | ( nb-json - ''' )

  nb_single_char = r2s ///
    (?:
      #{c_quoted_quote}
    | (?:
        (?! ')
        #{nb_json}
      )
    )
  ///yu



  # [119]
  # ns-single-char ::=
  #   nb-single-char - s-white

  ns_single_char = r2s ///
    (?:
      (?! #{s_white})
      #{nb_single_char}
    )
  ///yu



  # [120]
  # c-single-quoted(n,c) ::=
  #   ''' nb-single-text(n,c)
  #   '''

  c_single_quoted: (n, c)->
    # debug_rule("c_single_quoted",n,c)
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
    # debug_rule("nb_single_text",n,c)
    @case(
      c
      {
        'block-key': @rgx(re_nb_single_one_line)
        'flow-in': [ @nb_single_multi_line, n ]
        'flow-key': @rgx(re_nb_single_one_line)
        'flow-out': [ @nb_single_multi_line, n ]
      }
    )



  # [122]
  # nb-single-one-line ::=
  #   nb-single-char*

  re_nb_single_one_line = ///
    #{nb_single_char}*
  ///yu



  # [123]
  # nb-ns-single-in-line ::=
  #   ( s-white* ns-single-char )*

  re_nb_ns_single_in_line = ///
    (?:
      #{s_white}*
      #{ns_single_char}
    )*
  ///yu
  nb_ns_single_in_line = r2s re_nb_ns_single_in_line



  # [124]
  # s-single-next-line(n) ::=
  #   s-flow-folded(n)
  #   ( ns-single-char nb-ns-single-in-line
  #   ( s-single-next-line(n) | s-white* ) )?

  s_single_next_line: (n)->
    # debug_rule("s_single_next_line",n)
    @all(
      [ @s_flow_folded, n ]
      @rep(0, 1
        @all(
          @rgx(
            ///
              #{ns_single_char}
              #{nb_ns_single_in_line}
            ///yu
          )
          @any(
            [ @s_single_next_line, n ]
            @rep(0, null, @s_white)
          )
        ))
    )



  # [125]
  # nb-single-multi-line(n) ::=
  #   nb-ns-single-in-line
  #   ( s-single-next-line(n) | s-white* )

  nb_single_multi_line: (n)->
    # debug_rule("nb_single_multi_line",n)
    @all(
      @rgx(re_nb_ns_single_in_line)
      @any(
        [ @s_single_next_line, n ]
        @rep(0, null, @s_white)
      )
    )



  # [126]
  # ns-plain-first(c) ::=
  #   ( ns-char - c-indicator )
  #   | ( ( '?' | ':' | '-' )
  #   <followed_by_an_ns-plain-safe(c)> )

  ns_plain_first: (c)->
    # debug_rule("ns_plain_first",c)
    @any(
      @rgx(
        ///
          (?! #{c_indicator})
          #{ns_char}
        ///yu
      )
      @all(
        @rgx(
          ///
            [ ? : - ]
          ///yu
        )
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
    # debug_rule("ns_plain_safe",c)
    @case(
      c
      {
        'block-key': @ns_char
        'flow-in': @rgx(re_ns_plain_safe_in)
        'flow-key': @rgx(re_ns_plain_safe_in)
        'flow-out': @ns_char
      }
    )



  # [129]
  # ns-plain-safe-in ::=
  #   ns-char - c-flow-indicator

  re_ns_plain_safe_in = ///
    (?:
      (?! #{c_flow_indicator} )
      #{ns_char}
    )
  ///yu



  # [130]
  # ns-plain-char(c) ::=
  #   ( ns-plain-safe(c) - ':' - '#' )
  #   | ( <an_ns-char_preceding> '#' )
  #   | ( ':' <followed_by_an_ns-plain-safe(c)> )

  ns_plain_char: (c)->
    # debug_rule("ns_plain_char",c)
    @any(
      @but(
        [ @ns_plain_safe, c ]
        @chr(':')
        @chr('#')
      )
      @all(
        @chk('<=', @ns_char)
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
    # debug_rule("ns_plain",n,c)
    @case(
      c
      {
        'block-key': [ @ns_plain_one_line, c ]
        'flow-in': [ @ns_plain_multi_line, n, c ]
        'flow-key': [ @ns_plain_one_line, c ]
        'flow-out': [ @ns_plain_multi_line, n, c ]
      }
    )



  # [132]
  # nb-ns-plain-in-line(c) ::=
  #   ( s-white*
  #   ns-plain-char(c) )*

  nb_ns_plain_in_line: (c)->
    # debug_rule("nb_ns_plain_in_line",c)
    @rep(0, null
      @all(
        @rep(0, null, @s_white)
        [ @ns_plain_char, c ]
      ))



  # [133]
  # ns-plain-one-line(c) ::=
  #   ns-plain-first(c)
  #   nb-ns-plain-in-line(c)

  ns_plain_one_line: (c)->
    # debug_rule("ns_plain_one_line",c)
    @all(
      [ @ns_plain_first, c ]
      [ @nb_ns_plain_in_line, c ]
    )



  # [134]
  # s-ns-plain-next-line(n,c) ::=
  #   s-flow-folded(n)
  #   ns-plain-char(c) nb-ns-plain-in-line(c)

  s_ns_plain_next_line: (n, c)->
    # debug_rule("s_ns_plain_next_line",n,c)
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
    # debug_rule("ns_plain_multi_line",n,c)
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
    # debug_rule("in_flow",c)
    @flip(
      c
      {
        'block-key': "flow-key"
        'flow-in': "flow-in"
        'flow-key': "flow-key"
        'flow-out': "flow-in"
      }
    )



  # [137]
  # c-flow-sequence(n,c) ::=
  #   '[' s-separate(n,c)?
  #   ns-s-flow-seq-entries(n,in-flow(c))? ']'

  c_flow_sequence: (n, c)->
    # debug_rule("c_flow_sequence",n,c)
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
    # debug_rule("ns_s_flow_seq_entries",n,c)
    @all(
      [ @ns_flow_seq_entry, n, c ]
      @rep(0, 1, [ @s_separate, n, c ])
      @rep2(0, 1
        @all(
          @chr(',')
          @rep(0, 1, [ @s_separate, n, c ])
          @rep2(0, 1, [ @ns_s_flow_seq_entries, n, c ])
        ))
    )



  # [139]
  # ns-flow-seq-entry(n,c) ::=
  #   ns-flow-pair(n,c) | ns-flow-node(n,c)

  ns_flow_seq_entry: (n, c)->
    # debug_rule("ns_flow_seq_entry",n,c)
    @any(
      [ @ns_flow_pair, n, c ]
      [ @ns_flow_node, n, c ]
    )



  # [140]
  # c-flow-mapping(n,c) ::=
  #   '{' s-separate(n,c)?
  #   ns-s-flow-map-entries(n,in-flow(c))? '}'

  c_flow_mapping: (n, c)->
    # debug_rule("c_flow_mapping",n,c)
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
    # debug_rule("ns_s_flow_map_entries",n,c)
    @all(
      [ @ns_flow_map_entry, n, c ]
      @rep(0, 1, [ @s_separate, n, c ])
      @rep2(0, 1
        @all(
          @chr(',')
          @rep(0, 1, [ @s_separate, n, c ])
          @rep2(0, 1, [ @ns_s_flow_map_entries, n, c ])
        ))
    )



  # [142]
  # ns-flow-map-entry(n,c) ::=
  #   ( '?' s-separate(n,c)
  #   ns-flow-map-explicit-entry(n,c) )
  #   | ns-flow-map-implicit-entry(n,c)

  ws_lookahead = r2s ///
    (?=
      $
    | #{s_white}
    | #{line_break}
    )
  ///yu

  re_ns_flow_map_entry = ///
    \? #{ws_lookahead}
  ///yu

  ns_flow_map_entry: (n, c)->
    # debug_rule("ns_flow_map_entry",n,c)
    @any(
      @all(
        @rgx(re_ns_flow_map_entry)
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
    # debug_rule("ns_flow_map_explicit_entry",n,c)
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
    # debug_rule("ns_flow_map_implicit_entry",n,c)
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
    # debug_rule("ns_flow_map_yaml_key_entry",n,c)
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
    # debug_rule("c_ns_flow_map_empty_key_entry",n,c)
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
    # debug_rule("c_ns_flow_map_separate_value",n,c)
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
    # debug_rule("c_ns_flow_map_json_key_entry",n,c)
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
    # debug_rule("c_ns_flow_map_adjacent_value",n,c)
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

  re_ns_flow_pair = ///
    \? #{ws_lookahead}
  ///yu

  ns_flow_pair: (n, c)->
    # debug_rule("ns_flow_pair",n,c)
    @any(
      @all(
        @rgx(re_ns_flow_pair)
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
    # debug_rule("ns_flow_pair_entry",n,c)
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
    # debug_rule("ns_flow_pair_yaml_key_entry",n,c)
    @all(
      [ @ns_s_implicit_yaml_key, "flow-key" ]
      [ @c_ns_flow_map_separate_value, n, c ]
    )



  # [153]
  # c-ns-flow-pair-json-key-entry(n,c) ::=
  #   c-s-implicit-json-key(flow-key)
  #   c-ns-flow-map-adjacent-value(n,c)

  c_ns_flow_pair_json_key_entry: (n, c)->
    # debug_rule("c_ns_flow_pair_json_key_entry",n,c)
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
    # debug_rule("ns_s_implicit_yaml_key",c)
    @all(
      @max(1024)
      [ @ns_flow_yaml_node, null, c ]
      @rep(0, 1, @s_separate_in_line)
    )



  # [155]
  # c-s-implicit-json-key(c) ::=
  #   c-flow-json-node(n/a,c)
  #   s-separate-in-line?
  #   <at_most_1024_characters_altogether>

  c_s_implicit_json_key: (c)->
    # debug_rule("c_s_implicit_json_key",c)
    @all(
      @max(1024)
      [ @c_flow_json_node, null, c ]
      @rep(0, 1, @s_separate_in_line)
    )



  # [156]
  # ns-flow-yaml-content(n,c) ::=
  #   ns-plain(n,c)

  ns_flow_yaml_content: (n, c)->
    # debug_rule("ns_flow_yaml_content",n,c)
    [ @ns_plain, n, c ]



  # [157]
  # c-flow-json-content(n,c) ::=
  #   c-flow-sequence(n,c) | c-flow-mapping(n,c)
  #   | c-single-quoted(n,c) | c-double-quoted(n,c)

  c_flow_json_content: (n, c)->
    # debug_rule("c_flow_json_content",n,c)
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
    # debug_rule("ns_flow_content",n,c)
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
    # debug_rule("ns_flow_yaml_node",n,c)
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
          @e_scalar
        )
      )
    )



  # [160]
  # c-flow-json-node(n,c) ::=
  #   ( c-ns-properties(n,c)
  #   s-separate(n,c) )?
  #   c-flow-json-content(n,c)

  c_flow_json_node: (n, c)->
    # debug_rule("c_flow_json_node",n,c)
    @all(
      @rep(0, 1
        @all(
          [ @c_ns_properties, n, c ]
          [ @s_separate, n, c ]
        ))
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
    # debug_rule("ns_flow_node",n,c)
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
          @e_scalar
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
    # debug_rule("c_b_block_header",n)
    @all(
      @any(
        @all(
          [ @c_indentation_indicator, n ]
          @c_chomping_indicator
          @chk(
            '='
            @any(
              @end_of_stream
              @s_white
              @rgx(re_line_break)
            )
          )
        )
        @all(
          @c_chomping_indicator
          [ @c_indentation_indicator, n ]
          @chk(
            '='
            @any(
              @end_of_stream
              @s_white
              @rgx(re_line_break)
            )
          )
        )
      )
      @s_b_comment
    )



  # [163]
  # c-indentation-indicator(m) ::=
  #   ( ns-dec-digit => m = ns-dec-digit - x:30 )
  #   ( <empty> => m = auto-detect() )

  c_indentation_indicator: (n)->
    # debug_rule("c_indentation_indicator",n)
    @any(
      @if(@rng("\u{31}", "\u{39}"), @set('m', @ord(@match)))
      @if(@empty, @set('m', [ @auto_detect, n ]))
    )



  # [164]
  # c-chomping-indicator(t) ::=
  #   ( '-' => t = strip )
  #   ( '+' => t = keep )
  #   ( <empty> => t = clip )

  c_chomping_indicator: ->
    # debug_rule("c_chomping_indicator")
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
    # debug_rule("b_chomped_last",t)
    @case(
      t
      {
        'clip': @any( @b_as_line_feed, @end_of_stream )
        'keep': @any( @b_as_line_feed, @end_of_stream )
        'strip': @any( @rgx(re_line_break), @end_of_stream )
      }
    )



  # [166]
  # l-chomped-empty(n,t) ::=
  #   ( t = strip => l-strip-empty(n) )
  #   ( t = clip => l-strip-empty(n) )
  #   ( t = keep => l-keep-empty(n) )

  l_chomped_empty: (n, t)->
    # debug_rule("l_chomped_empty",n,t)
    @case(
      t
      {
        'clip': [ @l_strip_empty, n ]
        'keep': [ @l_keep_empty, n ]
        'strip': [ @l_strip_empty, n ]
      }
    )



  # [167]
  # l-strip-empty(n) ::=
  #   ( s-indent(<=n) b-non-content )*
  #   l-trail-comments(n)?

  l_strip_empty: (n)->
    # debug_rule("l_strip_empty",n)
    @all(
      @rep(0, null
        @all(
          [ @s_indent_le, n ]
          @rgx(re_line_break)
        ))
      @rep2(0, 1, [ @l_trail_comments, n ])
    )



  # [168]
  # l-keep-empty(n) ::=
  #   l-empty(n,block-in)*
  #   l-trail-comments(n)?

  l_keep_empty: (n)->
    # debug_rule("l_keep_empty",n)
    @all(
      @rep(0, null, [ @l_empty, n, "block-in" ])
      @rep2(0, 1, [ @l_trail_comments, n ])
    )



  # [169]
  # l-trail-comments(n) ::=
  #   s-indent(<n)
  #   c-nb-comment-text b-comment
  #   l-comment*

  l_trail_comments: (n)->
    # debug_rule("l_trail_comments",n)
    @all(
      [ @s_indent_lt, n ]
      @rgx(
        ///
          #{c_nb_comment_text}
          #{b_comment}
        ///yu
      )
      @rep(0, null, @l_comment)
    )



  # [170]
  # c-l+literal(n) ::=
  #   '|' c-b-block-header(m,t)
  #   l-literal-content(n+m,t)

  c_l_literal: (n)->
    # debug_rule("c_l_literal",n)
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
    # debug_rule("l_nb_literal_text",n)
    @all(
      @rep(0, null, [ @l_empty, n, "block-in" ])
      @rgx(re_s_indent_n(n))
      @rep2(1, null, @nb_char)
    )



  # [172]
  # b-nb-literal-next(n) ::=
  #   b-as-line-feed
  #   l-nb-literal-text(n)

  b_nb_literal_next: (n)->
    # debug_rule("b_nb_literal_next",n)
    @all(
      @b_as_line_feed
      [ @l_nb_literal_text, n ]
    )



  # [173]
  # l-literal-content(n,t) ::=
  #   ( l-nb-literal-text(n)
  #   b-nb-literal-next(n)*
  #   b-chomped-last(t) )?
  #   l-chomped-empty(n,t)

  l_literal_content: (n, t)->
    # debug_rule("l_literal_content",n,t)
    @all(
      @rep(0, 1
        @all(
          [ @l_nb_literal_text, n ]
          @rep(0, null, [ @b_nb_literal_next, n ])
          [ @b_chomped_last, t ]
        ))
      [ @l_chomped_empty, n, t ]
    )



  # [174]
  # c-l+folded(n) ::=
  #   '>' c-b-block-header(m,t)
  #   l-folded-content(n+m,t)

  c_l_folded: (n)->
    # debug_rule("c_l_folded",n)
    @all(
      @chr('>')
      [ @c_b_block_header, n ]
      [ @l_folded_content, @add(n, @m()), @t() ]
    )



  # [175]
  # s-nb-folded-text(n) ::=
  #   s-indent(n) ns-char
  #   nb-char*

  s_nb_folded_text: (n)->
    # debug_rule("s_nb_folded_text",n)
    @all(
      @rgx(re_s_indent_n(n))
      @ns_char
      @rep(0, null, @nb_char)
    )



  # [176]
  # l-nb-folded-lines(n) ::=
  #   s-nb-folded-text(n)
  #   ( b-l-folded(n,block-in) s-nb-folded-text(n) )*

  l_nb_folded_lines: (n)->
    # debug_rule("l_nb_folded_lines",n)
    @all(
      [ @s_nb_folded_text, n ]
      @rep(0, null
        @all(
          [ @b_l_folded, n, "block-in" ]
          [ @s_nb_folded_text, n ]
        ))
    )



  # [177]
  # s-nb-spaced-text(n) ::=
  #   s-indent(n) s-white
  #   nb-char*

  s_nb_spaced_text: (n)->
    # debug_rule("s_nb_spaced_text",n)
    @all(
      @rgx(re_s_indent_n(n))
      @s_white
      @rep(0, null, @nb_char)
    )



  # [178]
  # b-l-spaced(n) ::=
  #   b-as-line-feed
  #   l-empty(n,block-in)*

  b_l_spaced: (n)->
    # debug_rule("b_l_spaced",n)
    @all(
      @b_as_line_feed
      @rep(0, null, [ @l_empty, n, "block-in" ])
    )



  # [179]
  # l-nb-spaced-lines(n) ::=
  #   s-nb-spaced-text(n)
  #   ( b-l-spaced(n) s-nb-spaced-text(n) )*

  l_nb_spaced_lines: (n)->
    # debug_rule("l_nb_spaced_lines",n)
    @all(
      [ @s_nb_spaced_text, n ]
      @rep(0, null
        @all(
          [ @b_l_spaced, n ]
          [ @s_nb_spaced_text, n ]
        ))
    )



  # [180]
  # l-nb-same-lines(n) ::=
  #   l-empty(n,block-in)*
  #   ( l-nb-folded-lines(n) | l-nb-spaced-lines(n) )

  l_nb_same_lines: (n)->
    # debug_rule("l_nb_same_lines",n)
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
    # debug_rule("l_nb_diff_lines",n)
    @all(
      [ @l_nb_same_lines, n ]
      @rep(0, null
        @all(
          @b_as_line_feed
          [ @l_nb_same_lines, n ]
        ))
    )



  # [182]
  # l-folded-content(n,t) ::=
  #   ( l-nb-diff-lines(n)
  #   b-chomped-last(t) )?
  #   l-chomped-empty(n,t)

  l_folded_content: (n, t)->
    # debug_rule("l_folded_content",n,t)
    @all(
      @rep(0, 1
        @all(
          [ @l_nb_diff_lines, n ]
          [ @b_chomped_last, t ]
        ))
      [ @l_chomped_empty, n, t ]
    )



  # [183]
  # l+block-sequence(n) ::=
  #   ( s-indent(n+m)
  #   c-l-block-seq-entry(n+m) )+
  #   <for_some_fixed_auto-detected_m_>_0>

  l_block_sequence: (n)->
    return false unless m = @call [@auto_detect_indent, n], 'number'
    # debug_rule("l_block_sequence",n)
    @all(
      @rep(1, null
        @all(
          @rgx(re_s_indent_n(n + m))
          [ @c_l_block_seq_entry, @add(n, m) ]
        ))
    )



  # [184]
  # c-l-block-seq-entry(n) ::=
  #   '-' <not_followed_by_an_ns-char>
  #   s-l+block-indented(n,block-in)

  c_l_block_seq_entry: (n)->
    # debug_rule("c_l_block_seq_entry",n)
    @all(
      @chr('-')
      @chk('!', @ns_char)
      [ @s_l_block_indented, n, "block-in" ]
    )



  # [185]
  # s-l+block-indented(n,c) ::=
  #   ( s-indent(m)
  #   ( ns-l-compact-sequence(n+1+m)
  #   | ns-l-compact-mapping(n+1+m) ) )
  #   | s-l+block-node(n,c)
  #   | ( e-node s-l-comments )

  s_l_block_indented: (n, c)->
    m = @call [@auto_detect_indent, n], 'number'
    # debug_rule("s_l_block_indented",n,c)
    @any(
      @all(
        @rgx(re_s_indent_n(m))
        @any(
          [ @ns_l_compact_sequence, @add(n, @add(1, m)) ]
          [ @ns_l_compact_mapping, @add(n, @add(1, m)) ]
        )
      )
      [ @s_l_block_node, n, c ]
      @all(
        @e_node
        @s_l_comments
      )
    )



  # [186]
  # ns-l-compact-sequence(n) ::=
  #   c-l-block-seq-entry(n)
  #   ( s-indent(n) c-l-block-seq-entry(n) )*

  ns_l_compact_sequence: (n)->
    # debug_rule("ns_l_compact_sequence",n)
    @all(
      [ @c_l_block_seq_entry, n ]
      @rep(0, null
        @all(
          @rgx(re_s_indent_n(n))
          [ @c_l_block_seq_entry, n ]
        ))
    )



  # [187]
  # l+block-mapping(n) ::=
  #   ( s-indent(n+m)
  #   ns-l-block-map-entry(n+m) )+
  #   <for_some_fixed_auto-detected_m_>_0>

  l_block_mapping: (n)->
    return false unless m = @call [@auto_detect_indent, n], 'number'
    # debug_rule("l_block_mapping",n)
    @all(
      @rep(1, null
        @all(
          @rgx(re_s_indent_n(n + m))
          [ @ns_l_block_map_entry, @add(n, m) ]
        ))
    )



  # [188]
  # ns-l-block-map-entry(n) ::=
  #   c-l-block-map-explicit-entry(n)
  #   | ns-l-block-map-implicit-entry(n)

  ns_l_block_map_entry: (n)->
    # debug_rule("ns_l_block_map_entry",n)
    @any(
      [ @c_l_block_map_explicit_entry, n ]
      [ @ns_l_block_map_implicit_entry, n ]
    )



  # [189]
  # c-l-block-map-explicit-entry(n) ::=
  #   c-l-block-map-explicit-key(n)
  #   ( l-block-map-explicit-value(n)
  #   | e-node )

  c_l_block_map_explicit_entry: (n)->
    # debug_rule("c_l_block_map_explicit_entry",n)
    @all(
      [ @c_l_block_map_explicit_key, n ]
      @any(
        [ @l_block_map_explicit_value, n ]
        @e_node
      )
    )



  # [190]
  # c-l-block-map-explicit-key(n) ::=
  #   '?'
  #   s-l+block-indented(n,block-out)

  c_l_block_map_explicit_key: (n)->
    # debug_rule("c_l_block_map_explicit_key",n)
    @all(
      @chr('?')
      @chk(
        '='
        @any(
          @end_of_stream
          @s_white
          @rgx(re_line_break)
        )
      )
      [ @s_l_block_indented, n, "block-out" ]
    )



  # [191]
  # l-block-map-explicit-value(n) ::=
  #   s-indent(n)
  #   ':' s-l+block-indented(n,block-out)

  l_block_map_explicit_value: (n)->
    # debug_rule("l_block_map_explicit_value",n)
    @all(
      @rgx(re_s_indent_n(n))
      @chr(':')
      [ @s_l_block_indented, n, "block-out" ]
    )



  # [192]
  # ns-l-block-map-implicit-entry(n) ::=
  #   (
  #   ns-s-block-map-implicit-key
  #   | e-node )
  #   c-l-block-map-implicit-value(n)

  ns_l_block_map_implicit_entry: (n)->
    # debug_rule("ns_l_block_map_implicit_entry",n)
    @all(
      @any(
        @any(
          [ @c_s_implicit_json_key, "block-key" ]
          [ @ns_s_implicit_yaml_key, "block-key" ]
        )
        @e_node
      )
      [ @c_l_block_map_implicit_value, n ]
    )



  # [194]
  # c-l-block-map-implicit-value(n) ::=
  #   ':' (
  #   s-l+block-node(n,block-out)
  #   | ( e-node s-l-comments ) )

  c_l_block_map_implicit_value: (n)->
    # debug_rule("c_l_block_map_implicit_value",n)
    @all(
      @chr(':')
      @any(
        [ @s_l_block_node, n, "block-out" ]
        @all(
          @e_node
          @s_l_comments
        )
      )
    )



  # [195]
  # ns-l-compact-mapping(n) ::=
  #   ns-l-block-map-entry(n)
  #   ( s-indent(n) ns-l-block-map-entry(n) )*

  ns_l_compact_mapping: (n)->
    # debug_rule("ns_l_compact_mapping",n)
    @all(
      [ @ns_l_block_map_entry, n ]
      @rep(0, null
        @all(
          @rgx(re_s_indent_n(n))
          [ @ns_l_block_map_entry, n ]
        ))
    )



  # [196]
  # s-l+block-node(n,c) ::=
  #   s-l+block-in-block(n,c) | s-l+flow-in-block(n)

  s_l_block_node: (n, c)->
    # debug_rule("s_l_block_node",n,c)
    @any(
      [ @s_l_block_in_block, n, c ]
      [ @s_l_flow_in_block, n ]
    )



  # [197]
  # s-l+flow-in-block(n) ::=
  #   s-separate(n+1,flow-out)
  #   ns-flow-node(n+1,flow-out) s-l-comments

  s_l_flow_in_block: (n)->
    # debug_rule("s_l_flow_in_block",n)
    @all(
      [ @s_separate, @add(n, 1), "flow-out" ]
      [ @ns_flow_node, @add(n, 1), "flow-out" ]
      @s_l_comments
    )



  # [198]
  # s-l+block-in-block(n,c) ::=
  #   s-l+block-scalar(n,c) | s-l+block-collection(n,c)

  s_l_block_in_block: (n, c)->
    # debug_rule("s_l_block_in_block",n,c)
    @any(
      [ @s_l_block_scalar, n, c ]
      [ @s_l_block_collection, n, c ]
    )



  # [199]
  # s-l+block-scalar(n,c) ::=
  #   s-separate(n+1,c)
  #   ( c-ns-properties(n+1,c) s-separate(n+1,c) )?
  #   ( c-l+literal(n) | c-l+folded(n) )

  s_l_block_scalar: (n, c)->
    # debug_rule("s_l_block_scalar",n,c)
    @all(
      [ @s_separate, @add(n, 1), c ]
      @rep(0, 1
        @all(
          [ @c_ns_properties, @add(n, 1), c ]
          [ @s_separate, @add(n, 1), c ]
        ))
      @any(
        [ @c_l_literal, n ]
        [ @c_l_folded, n ]
      )
    )



  # [200]
  # s-l+block-collection(n,c) ::=
  #   ( s-separate(n+1,c)
  #   c-ns-properties(n+1,c) )?
  #   s-l-comments
  #   ( l+block-sequence(seq-spaces(n,c))
  #   | l+block-mapping(n) )

  s_l_block_collection: (n, c)->
    # debug_rule("s_l_block_collection",n,c)
    @all(
      @rep(0, 1
        @all(
          [ @s_separate, @add(n, 1), c ]
          @any(
            @all(
              [ @c_ns_properties, @add(n, 1), c ]
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
        ))
      @s_l_comments
      @any(
        [ @l_block_sequence, [ @seq_spaces, n, c ] ]
        [ @l_block_mapping, n ]
      )
    )



  # [201]
  # seq-spaces(n,c) ::=
  #   ( c = block-out => n-1 )
  #   ( c = block-in => n )

  seq_spaces: (n, c)->
    # debug_rule("seq_spaces",n,c)
    @flip(
      c
      {
        'block-in': n
        'block-out': @sub(n, 1)
      }
    )



  # [202]
  # l-document-prefix ::=
  #   c-byte-order-mark? l-comment*

  l_document_prefix: ->
    # debug_rule("l_document_prefix")
    @all(
      @rep(0, 1, @chr(c_byte_order_mark))
      @rep2(0, null, @l_comment)
    )



  # [203]
  # c-directives-end ::=
  #   '-' '-' '-'

  re_c_directives_end = ///
    - - -
    (?=
      $
    | #{s_white}
    | #{line_break}
    )
  ///yu
  c_directives_end = r2s re_c_directives_end

  c_directives_end: ->
    # debug_rule("c_directives_end")
    @rgx(re_c_directives_end)



  # [204]
  # c-document-end ::=
  #   '.' '.' '.'

  re_c_document_end = ///
    \. \. \.
  ///yu
  c_document_end = r2s re_c_document_end

  c_document_end: ->
    # debug_rule("c_document_end")
    @rgx(re_c_document_end)



  # [205]
  # l-document-suffix ::=
  #   c-document-end s-l-comments

  l_document_suffix: ->
    # debug_rule("l_document_suffix")
    @all(
      @c_document_end
      @s_l_comments
    )



  # [206]
  # c-forbidden ::=
  #   <start_of_line>
  #   ( c-directives-end | c-document-end )
  #   ( b-char | s-white | <end_of_file> )

  re_c_forbidden = ///
    (?:
      #{c_directives_end}
    | #{c_document_end}
    )
    (?:
      #{b_char}
    | #{s_white}
    | $
  )
  ///yu

  c_forbidden: ->
    # debug_rule("c_forbidden")
    @all(
      @start_of_line
      @rgx(re_c_forbidden)
    )



  # [207]
  # l-bare-document ::=
  #   s-l+block-node(-1,block-in)
  #   <excluding_c-forbidden_content>

  l_bare_document: ->
    # debug_rule("l_bare_document")
    @all(
      @exclude(@c_forbidden)
      [ @s_l_block_node, -1, "block-in" ]
    )



  # [208]
  # l-explicit-document ::=
  #   c-directives-end
  #   ( l-bare-document
  #   | ( e-node s-l-comments ) )

  l_explicit_document: ->
    # debug_rule("l_explicit_document")
    @all(
      @c_directives_end
      @any(
        @l_bare_document
        @all(
          @e_node
          @s_l_comments
        )
      )
    )



  # [209]
  # l-directive-document ::=
  #   l-directive+
  #   l-explicit-document

  l_directive_document: ->
    # debug_rule("l_directive_document")
    @all(
      @rep(1, null, @l_directive)
      @l_explicit_document
    )



  # [210]
  # l-any-document ::=
  #   l-directive-document
  #   | l-explicit-document
  #   | l-bare-document

  l_any_document: ->
    # debug_rule("l_any_document")
    @any(
      @l_directive_document
      @l_explicit_document
      @l_bare_document
    )



  # [211]
  # l-yaml-stream ::=
  #   l-document-prefix* l-any-document?
  #   ( ( l-document-suffix+ l-document-prefix*
  #   l-any-document? )
  #   | ( l-document-prefix* l-explicit-document? ) )*

  l_yaml_stream: ->
    # debug_rule("l_yaml_stream")
    @all(
      @l_document_prefix
      @rep(0, 1, @l_any_document)
      @rep2(0, null
        @any(
          @all(
            @l_document_suffix
            @rep(0, null, @l_document_prefix)
            @rep2(0, 1, @l_any_document)
          )
          @all(
            @l_document_prefix
            @rep(0, 1, @l_explicit_document)
          )
        ))
    )



