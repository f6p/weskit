module Weskit::WML::Parsers
class KPEG
  # :stopdoc:

    # This is distinct from setup_parser so that a standalone parser
    # can redefine #initialize and still have access to the proper
    # parser setup code.
    def initialize(str, debug=false)
      setup_parser(str, debug)
    end



    # Prepares for parsing +str+.  If you define a custom initialize you must
    # call this method before #parse
    def setup_parser(str, debug=false)
      @string = str
      @pos = 0
      @memoizations = Hash.new { |h,k| h[k] = {} }
      @result = nil
      @failed_rule = nil
      @failing_rule_offset = -1

      setup_foreign_grammar
    end

    attr_reader :string
    attr_reader :failing_rule_offset
    attr_accessor :result, :pos

    
    def current_column(target=pos)
      if c = string.rindex("\n", target-1)
        return target - c - 1
      end

      target + 1
    end

    def current_line(target=pos)
      cur_offset = 0
      cur_line = 0

      string.each_line do |line|
        cur_line += 1
        cur_offset += line.size
        return cur_line if cur_offset >= target
      end

      -1
    end

    def lines
      lines = []
      string.each_line { |l| lines << l }
      lines
    end



    def get_text(start)
      @string[start..@pos-1]
    end

    def show_pos
      width = 10
      if @pos < width
        "#{@pos} (\"#{@string[0,@pos]}\" @ \"#{@string[@pos,width]}\")"
      else
        "#{@pos} (\"... #{@string[@pos - width, width]}\" @ \"#{@string[@pos,width]}\")"
      end
    end

    def failure_info
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "line #{l}, column #{c}: failed rule '#{info.name}' = '#{info.rendered}'"
      else
        "line #{l}, column #{c}: failed rule '#{@failed_rule}'"
      end
    end

    def failure_caret
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      line = lines[l-1]
      "#{line}\n#{' ' * (c - 1)}^"
    end

    def failure_character
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset
      lines[l-1][c-1, 1]
    end

    def failure_oneline
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      char = lines[l-1][c-1, 1]

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "@#{l}:#{c} failed rule '#{info.name}', got '#{char}'"
      else
        "@#{l}:#{c} failed rule '#{@failed_rule}', got '#{char}'"
      end
    end

    class ParseError < RuntimeError
    end

    def raise_error
      raise ParseError, failure_oneline
    end

    def show_error(io=STDOUT)
      error_pos = @failing_rule_offset
      line_no = current_line(error_pos)
      col_no = current_column(error_pos)

      io.puts "On line #{line_no}, column #{col_no}:"

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        io.puts "Failed to match '#{info.rendered}' (rule '#{info.name}')"
      else
        io.puts "Failed to match rule '#{@failed_rule}'"
      end

      io.puts "Got: #{string[error_pos,1].inspect}"
      line = lines[line_no-1]
      io.puts "=> #{line}"
      io.print(" " * (col_no + 3))
      io.puts "^"
    end

    def set_failed_rule(name)
      if @pos > @failing_rule_offset
        @failed_rule = name
        @failing_rule_offset = @pos
      end
    end

    attr_reader :failed_rule

    def match_string(str)
      len = str.size
      if @string[pos,len] == str
        @pos += len
        return str
      end

      return nil
    end

    def scan(reg)
      if m = reg.match(@string[@pos..-1])
        width = m.end(0)
        @pos += width
        return true
      end

      return nil
    end

    if "".respond_to? :getbyte
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string.getbyte @pos
        @pos += 1
        s
      end
    else
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string[@pos]
        @pos += 1
        s
      end
    end

    def parse(rule=nil)
      # We invoke the rules indirectly via apply
      # instead of by just calling them as methods because
      # if the rules use left recursion, apply needs to
      # manage that.

      if !rule
        apply(:_root)
      else
        method = rule.gsub("-","_hyphen_")
        apply :"_#{method}"
      end
    end

    class MemoEntry
      def initialize(ans, pos)
        @ans = ans
        @pos = pos
        @result = nil
        @set = false
        @left_rec = false
      end

      attr_reader :ans, :pos, :result, :set
      attr_accessor :left_rec

      def move!(ans, pos, result)
        @ans = ans
        @pos = pos
        @result = result
        @set = true
        @left_rec = false
      end
    end

    def external_invoke(other, rule, *args)
      old_pos = @pos
      old_string = @string

      @pos = other.pos
      @string = other.string

      begin
        if val = __send__(rule, *args)
          other.pos = @pos
          other.result = @result
        else
          other.set_failed_rule "#{self.class}##{rule}"
        end
        val
      ensure
        @pos = old_pos
        @string = old_string
      end
    end

    def apply_with_args(rule, *args)
      memo_key = [rule, args]
      if m = @memoizations[memo_key][@pos]
        @pos = m.pos
        if !m.set
          m.left_rec = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        m = MemoEntry.new(nil, @pos)
        @memoizations[memo_key][@pos] = m
        start_pos = @pos

        ans = __send__ rule, *args

        lr = m.left_rec

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr
          return grow_lr(rule, args, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def apply(rule)
      if m = @memoizations[rule][@pos]
        @pos = m.pos
        if !m.set
          m.left_rec = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        m = MemoEntry.new(nil, @pos)
        @memoizations[rule][@pos] = m
        start_pos = @pos

        ans = __send__ rule

        lr = m.left_rec

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr
          return grow_lr(rule, nil, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def grow_lr(rule, args, start_pos, m)
      while true
        @pos = start_pos
        @result = m.result

        if args
          ans = __send__ rule, *args
        else
          ans = __send__ rule
        end
        return nil unless ans

        break if @pos <= m.pos

        m.move! ans, @pos, @result
      end

      @result = m.result
      @pos = m.pos
      return m.ans
    end

    class RuleInfo
      def initialize(name, rendered)
        @name = name
        @rendered = rendered
      end

      attr_reader :name, :rendered
    end

    def self.rule_info(name, rendered)
      RuleInfo.new(name, rendered)
    end


  # :startdoc:


  attr_accessor :result

  private

  def strip_chars string, chars
    string[chars, string.length - chars * 2]
  end


  # :stopdoc:
  def setup_foreign_grammar; end

  # id = < /[a-z][0-9a-z_]*/i > { text }
  def _id

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?i-mx:[a-z][0-9a-z_]*)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_id unless _tmp
    return _tmp
  end

  # ids = (ids:i1 - "," - ids:i2 { i1 + i2 } | id:i { [i] })
  def _ids

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_ids)
        i1 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(",")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_ids)
        i2 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  i1 + i2 ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_id)
        i = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  [i] ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_ids unless _tmp
    return _tmp
  end

  # item = (attribute | attributes | element)
  def _item

    _save = self.pos
    while true # choice
      _tmp = apply(:_attribute)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_attributes)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_element)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_item unless _tmp
    return _tmp
  end

  # items = (items:i1 items:i2 { i1 + i2 } | item:i { (i.is_a? Array) ? i : [i] })
  def _items

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_items)
        i1 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_items)
        i2 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  i1 + i2 ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_item)
        i = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  (i.is_a? Array) ? i : [i] ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_items unless _tmp
    return _tmp
  end

  # contents = items?:i { i.to_a }
  def _contents

    _save = self.pos
    while true # sequence
      _save1 = self.pos
      _tmp = apply(:_items)
      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      i = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  i.to_a ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_contents unless _tmp
    return _tmp
  end

  # single_attr = - id:n - "=" - val:v - eol { Weskit::WML::Attribute.new n, *v }
  def _single_attr

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_id)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("=")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_val)
      v = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_eol)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  Weskit::WML::Attribute.new n, *v ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_single_attr unless _tmp
    return _tmp
  end

  # multiple_attrs = - ids:n - "=" - vals:v - eol { n.reduce(Array.new) do |attrs, name|                    value =v.shift or [nil]                    attrs << Weskit::WML::Attribute.new(name, *value)                  end }
  def _multiple_attrs

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_ids)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("=")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_vals)
      v = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_eol)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  n.reduce(Array.new) do |attrs, name|
                   value =v.shift or [nil]
                   attrs << Weskit::WML::Attribute.new(name, *value)
                 end ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_multiple_attrs unless _tmp
    return _tmp
  end

  # attribute = blk_lines single_attr:a blk_lines { a }
  def _attribute

    _save = self.pos
    while true # sequence
      _tmp = apply(:_blk_lines)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_single_attr)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_blk_lines)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  a ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_attribute unless _tmp
    return _tmp
  end

  # attributes = blk_lines multiple_attrs:a blk_lines { a }
  def _attributes

    _save = self.pos
    while true # sequence
      _tmp = apply(:_blk_lines)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_multiple_attrs)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_blk_lines)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  a ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_attributes unless _tmp
    return _tmp
  end

  # code = < /<<.*?>>/m > { [strip_chars(text, 2), {:code => true}] }
  def _code

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?m-ix:<<.*?>>)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [strip_chars(text, 2), {:code => true}] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_code unless _tmp
    return _tmp
  end

  # in_brackets = < /\(.*?\)/m > { [strip_chars(text, 1)] }
  def _in_brackets

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?m-ix:\(.*?\))/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [strip_chars(text, 1)] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_in_brackets unless _tmp
    return _tmp
  end

  # in_quotes = < /".*?"/m > { [strip_chars(text, 1)] }
  def _in_quotes

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?m-ix:".*?")/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [strip_chars(text, 1)] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_in_quotes unless _tmp
    return _tmp
  end

  # raw = < /.*/ > { [text.strip] }
  def _raw

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?-mix:.*)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [text.strip] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_raw unless _tmp
    return _tmp
  end

  # escaped = (in_quotes:s1 escaped:s2 { s1[0] += '"' + s2[0] ; s1 } | in_quotes)
  def _escaped

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_in_quotes)
        s1 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_escaped)
        s2 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  s1[0] += '"' + s2[0] ; s1 ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply(:_in_quotes)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_escaped unless _tmp
    return _tmp
  end

  # i18n = "_" - (in_brackets | in_quotes):s { [s[0], {:translatable => true}] }
  def _i18n

    _save = self.pos
    while true # sequence
      _tmp = match_string("_")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_in_brackets)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_in_quotes)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      s = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [s[0], {:translatable => true}] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_i18n unless _tmp
    return _tmp
  end

  # val = (val:v1 - "+" sp_lf val:v2 { v1[0] += v2[0] ; v1 } | escaped | i18n | code | in_brackets | in_quotes | raw)
  def _val

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_val)
        v1 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("+")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_sp_lf)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_val)
        v2 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  v1[0] += v2[0] ; v1 ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply(:_escaped)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_i18n)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_code)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_in_brackets)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_in_quotes)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_raw)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_val unless _tmp
    return _tmp
  end

  # vals = (vals:v1 - "," - vals:v2 { v1 + v2 } | val:v { [v] })
  def _vals

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_vals)
        v1 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(",")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_vals)
        v2 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  v1 + v2 ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_val)
        v = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  [v] ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_vals unless _tmp
    return _tmp
  end

  # amendment = - amending_tag:n - eol contents:c - closing_tag(n) - eol { Weskit::WML::Element.new(n, :amendment => true).push *c }
  def _amendment

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_amending_tag)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_eol)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_contents)
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_closing_tag, n)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_eol)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  Weskit::WML::Element.new(n, :amendment => true).push *c ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_amendment unless _tmp
    return _tmp
  end

  # regular = - opening_tag:n - eol contents:c - closing_tag(n) - eol { Weskit::WML::Element.new(n).push *c }
  def _regular

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_opening_tag)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_eol)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_contents)
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_closing_tag, n)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_eol)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  Weskit::WML::Element.new(n).push *c ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_regular unless _tmp
    return _tmp
  end

  # element = blk_lines (amendment | regular):e blk_lines { e }
  def _element

    _save = self.pos
    while true # sequence
      _tmp = apply(:_blk_lines)
      unless _tmp
        self.pos = _save
        break
      end

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_amendment)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_regular)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      e = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_blk_lines)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  e ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_element unless _tmp
    return _tmp
  end

  # amending_tag = "[+" id:n "]" { n }
  def _amending_tag

    _save = self.pos
    while true # sequence
      _tmp = match_string("[+")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_id)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("]")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  n ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_amending_tag unless _tmp
    return _tmp
  end

  # closing_tag = "[/" id:n "]" &{ n == m }
  def _closing_tag(m)

    _save = self.pos
    while true # sequence
      _tmp = match_string("[/")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_id)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("]")
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = begin;  n == m ; end
      self.pos = _save1
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_closing_tag unless _tmp
    return _tmp
  end

  # opening_tag = "[" id:n "]" { n }
  def _opening_tag

    _save = self.pos
    while true # sequence
      _tmp = match_string("[")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_id)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("]")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  n ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_opening_tag unless _tmp
    return _tmp
  end

  # eof = !.
  def _eof
    _save = self.pos
    _tmp = get_byte
    _tmp = _tmp ? nil : true
    self.pos = _save
    set_failed_rule :_eof unless _tmp
    return _tmp
  end

  # eol = ("\n" | "\n")
  def _eol

    _save = self.pos
    while true # choice
      _tmp = match_string("\r\n")
      break if _tmp
      self.pos = _save
      _tmp = match_string("\n")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_eol unless _tmp
    return _tmp
  end

  # sp = (" " | "\t")
  def _sp

    _save = self.pos
    while true # choice
      _tmp = match_string(" ")
      break if _tmp
      self.pos = _save
      _tmp = match_string("\t")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_sp unless _tmp
    return _tmp
  end

  # - = sp*
  def __hyphen_
    while true
      _tmp = apply(:_sp)
      break unless _tmp
    end
    _tmp = true
    set_failed_rule :__hyphen_ unless _tmp
    return _tmp
  end

  # sp_lf = (sp | eol)*
  def _sp_lf
    while true

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_sp)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_eol)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_sp_lf unless _tmp
    return _tmp
  end

  # blk_lines = (- eol)*
  def _blk_lines
    while true

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_eol)
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_blk_lines unless _tmp
    return _tmp
  end

  # root = contents:c { c.empty? ? nil : Weskit::WML::Root.new.push(*c) }
  def _root

    _save = self.pos
    while true # sequence
      _tmp = apply(:_contents)
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  c.empty? ? nil : Weskit::WML::Root.new.push(*c) ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_root unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_id] = rule_info("id", "< /[a-z][0-9a-z_]*/i > { text }")
  Rules[:_ids] = rule_info("ids", "(ids:i1 - \",\" - ids:i2 { i1 + i2 } | id:i { [i] })")
  Rules[:_item] = rule_info("item", "(attribute | attributes | element)")
  Rules[:_items] = rule_info("items", "(items:i1 items:i2 { i1 + i2 } | item:i { (i.is_a? Array) ? i : [i] })")
  Rules[:_contents] = rule_info("contents", "items?:i { i.to_a }")
  Rules[:_single_attr] = rule_info("single_attr", "- id:n - \"=\" - val:v - eol { Weskit::WML::Attribute.new n, *v }")
  Rules[:_multiple_attrs] = rule_info("multiple_attrs", "- ids:n - \"=\" - vals:v - eol { n.reduce(Array.new) do |attrs, name|                    value =v.shift or [nil]                    attrs << Weskit::WML::Attribute.new(name, *value)                  end }")
  Rules[:_attribute] = rule_info("attribute", "blk_lines single_attr:a blk_lines { a }")
  Rules[:_attributes] = rule_info("attributes", "blk_lines multiple_attrs:a blk_lines { a }")
  Rules[:_code] = rule_info("code", "< /<<.*?>>/m > { [strip_chars(text, 2), {:code => true}] }")
  Rules[:_in_brackets] = rule_info("in_brackets", "< /\\(.*?\\)/m > { [strip_chars(text, 1)] }")
  Rules[:_in_quotes] = rule_info("in_quotes", "< /\".*?\"/m > { [strip_chars(text, 1)] }")
  Rules[:_raw] = rule_info("raw", "< /.*/ > { [text.strip] }")
  Rules[:_escaped] = rule_info("escaped", "(in_quotes:s1 escaped:s2 { s1[0] += '\"' + s2[0] ; s1 } | in_quotes)")
  Rules[:_i18n] = rule_info("i18n", "\"_\" - (in_brackets | in_quotes):s { [s[0], {:translatable => true}] }")
  Rules[:_val] = rule_info("val", "(val:v1 - \"+\" sp_lf val:v2 { v1[0] += v2[0] ; v1 } | escaped | i18n | code | in_brackets | in_quotes | raw)")
  Rules[:_vals] = rule_info("vals", "(vals:v1 - \",\" - vals:v2 { v1 + v2 } | val:v { [v] })")
  Rules[:_amendment] = rule_info("amendment", "- amending_tag:n - eol contents:c - closing_tag(n) - eol { Weskit::WML::Element.new(n, :amendment => true).push *c }")
  Rules[:_regular] = rule_info("regular", "- opening_tag:n - eol contents:c - closing_tag(n) - eol { Weskit::WML::Element.new(n).push *c }")
  Rules[:_element] = rule_info("element", "blk_lines (amendment | regular):e blk_lines { e }")
  Rules[:_amending_tag] = rule_info("amending_tag", "\"[+\" id:n \"]\" { n }")
  Rules[:_closing_tag] = rule_info("closing_tag", "\"[/\" id:n \"]\" &{ n == m }")
  Rules[:_opening_tag] = rule_info("opening_tag", "\"[\" id:n \"]\" { n }")
  Rules[:_eof] = rule_info("eof", "!.")
  Rules[:_eol] = rule_info("eol", "(\"\\n\" | \"\\n\")")
  Rules[:_sp] = rule_info("sp", "(\" \" | \"\\t\")")
  Rules[:__hyphen_] = rule_info("-", "sp*")
  Rules[:_sp_lf] = rule_info("sp_lf", "(sp | eol)*")
  Rules[:_blk_lines] = rule_info("blk_lines", "(- eol)*")
  Rules[:_root] = rule_info("root", "contents:c { c.empty? ? nil : Weskit::WML::Root.new.push(*c) }")
  # :startdoc:
end

  end
