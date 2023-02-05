module WMLHelpers
  def sample_amendment
    e = Weskit::WML::Element.new :bar, :amendment => true
    e.push Weskit::WML::Attribute.new :bat, :baz
  end

  def document_with_amendment
    <<-doc
      [foo]
      [/foo]
      [+foo]
        bat=baz
      [/foo]
    doc
  end

  def document_with_empty_lines
    <<-doc
      
      [a]
        b=c
      [/a]
      
      [d]
        
        e=f
        
      [/d]
      
    doc
  end

  def sample_elements
    a = Weskit::WML::Element.new :a
    b = Weskit::WML::Element.new :b
    c = Weskit::WML::Element.new :c
    d = Weskit::WML::Element.new :d
    a << (b.push c, d)
  end
end