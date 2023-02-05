shared_examples_for 'a container' do
  it 'can delete stored item' do
    container << (element = Weskit::WML::Element.new :foo)
    expect { container.delete element }.to change { container.contents.size }.by(-1)
  end

  it 'can determine if item exists' do
    container << (element = Weskit::WML::Element.new :foo)
    container.exists?(element).should be_true
  end

  it 'expose attrs and elems' do
    container << Weskit::WML::Attribute.new(:foo, :bar)
    container << Weskit::WML::Element.new(:baz)

    container.should have(2).contents
    container.should have(1).attrs
    container.should have(1).elems
  end

  it 'expose contents methods' do
    %w{each empty? first last size to_a}.each do |method|
      container.should respond_to(method)
    end
  end

  it 'has associated builder' do
    container.build do
      key :foo
      name {}
    end

    container[:key].should match_value_of(:foo)
    container[0].should have_same_identifier_as(:name)
  end
  
  it 'has hash like access' do
    container << (attribute = Weskit::WML::Attribute.new :foo, :bar)
    container << (element = Weskit::WML::Element.new :baz)

    container[:foo].should match_value_of(:bar)
    container[0].should have_same_representation_as(element)
  end
end

shared_examples_for 'basic  parser' do
  context 'ignores' do
    specify 'directives' do
      data = <<-DOC
        {~/path/to.cfg}
        #undef SOME_STUFF
      DOC

      parsed = Weskit::WML::Parser.string data, parser
      parsed.should be_nil
    end

    specify 'blank lines' do
      parsed = Weskit::WML::Parser.string document_with_empty_lines, parser
      parsed.should_not be_nil
    end
  end

  context 'attribute' do
    specify 'raw' do
      parsed = Weskit::WML::Parser.string 'a=b', parser
      parsed[:a].should match_value_of(:b)
    end

    specify 'escape sequence' do
      parsed = Weskit::WML::Parser.string %Q{ a= "b "" c" }, parser
      parsed[:a].should match_value_of('b " c')
    end
  end

  context 'element' do
    specify 'default' do
      parsed = Weskit::WML::Parser.string "[foo]\n[/foo]", parser
      parsed[0].should have_identifier_of(:foo)
    end

    specify 'amending' do
      parsed = Weskit::WML::Parser.string document_with_amendment, parser
      parsed[0][:bat].should match_value_of(:baz)
    end
  end
end

shared_examples_for 'a searchable' do
  specify 'append amending elements' do
    searchable << Weskit::WML::Element.new(:bar)
    searchable << sample_amendment

    searchable.should have(1).elems
    searchable.find(:bar, false)[:bat].should match_value_of(:baz)
  end

  specify 'finds nested elements' do
    searchable << sample_elements
    searchable.find(:a, false).find(:b).find(:c).size.should eq(1)
  end

  specify 'finds elements recursively' do
    searchable << sample_elements
    searchable << Weskit::WML::Element.new(:b)

    searchable.find_recursively do |item|
      item.name == :b
    end.size.should eq(2)
  end
end

shared_examples_for 'basic parser' do
  context 'ignores' do
    specify 'directives' do
      data = <<-DOC
        {~/path/to.cfg}
        #undef SOME_STUFF
      DOC

      parsed = Weskit::WML::Parser.string data, parser
      parsed.should be_nil
    end

    specify 'blank lines' do
      parsed = Weskit::WML::Parser.string document_with_empty_lines, parser
      parsed.should_not be_nil
    end
  end

  context 'attribute' do
    specify 'raw' do
      parsed = Weskit::WML::Parser.string 'a=b', parser
      parsed[:a].should match_value_of(:b)
    end

    specify 'escape sequence' do
      parsed = Weskit::WML::Parser.string %Q{ a= "b "" c" }, parser
      parsed[:a].should match_value_of('b " c')
    end
  end

  context 'element' do
    specify 'default' do
      parsed = Weskit::WML::Parser.string "[foo]\n[/foo]", parser
      parsed[0].should have_identifier_of(:foo)
    end

    specify 'amending' do
      parsed = Weskit::WML::Parser.string document_with_amendment, parser
      parsed[0][:bat].should match_value_of(:baz)
    end
  end
end
