require 'wml_spec_helper'

describe Weskit::WML::Parser do
  include WMLHelpers

  context 'with KPEG backend' do
    let(:backend) { :kpeg }

    it_should_behave_like 'basic parser' do
      let(:parser) { backend }
    end

    context 'attribute' do
      specify 'code' do
        parsed = Weskit::WML::Parser.string ' a= <<b>> ', backend
        parsed[:a].attribute.should be_code
        parsed[:a].should match_value_of(:b)
      end

      specify 'concated' do
        parsed = Weskit::WML::Parser.string ' a= _ "a" + 1 ', backend
        parsed[:a].attribute.should be_translatable
        parsed[:a].should match_value_of(:a1)
      end

      specify 'multiline' do
        parsed = Weskit::WML::Parser.string %Q{a= "b \n c"}, backend
        parsed[:a].attribute.should be_multiline
        parsed[:a].should match_value_of("b \n c")
      end

      specify 'multiple' do
        parsed = Weskit::WML::Parser.string %Q{ a, b = _"a", <<b>> }, backend

        parsed[:a].attribute.should be_translatable
        parsed[:a].should match_value_of(:a)

        parsed[:b].attribute.should be_code
        parsed[:b].should match_value_of(:b)
      end

      specify 'translatable' do
        parsed = Weskit::WML::Parser.string ' a= _ "b" ', backend
        parsed[:a].attribute.should be_translatable
        parsed[:a].should match_value_of(:b)
      end
    end

    context 'element' do
      specify 'default' do
        parsed = Weskit::WML::Parser.string "[foo]\n[/foo]", backend
        parsed[0].should have_identifier_of(:foo)
      end

      specify 'amending' do
        parsed = Weskit::WML::Parser.string document_with_amendment, backend
        parsed[0][:bat].should match_value_of(:baz)
      end
    end
  end

  context 'with Simple backend' do
    let(:backend) { :simple }

    it_should_behave_like 'basic parser' do
      let(:parser) { backend }
    end

    context 'attribute' do
      specify 'multiline' do
        parsed = Weskit::WML::Parser.string %Q{a = "a \n b"}, backend
        parsed[:a].should match_value_of('a...')
      end
    end
  end
end
