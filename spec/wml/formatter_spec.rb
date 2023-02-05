require 'wml_spec_helper'

describe Weskit::WML::Formatter do
  include WMLHelpers

  subject { Weskit::WML::Formatter.default }

  let(:formatter) { subject }

  specify 'can be initialized as color default or pain' do
    Weskit::WML::Formatter.color.should be_kind_of(Weskit::WML::Formatter)
    Weskit::WML::Formatter.default.should be_kind_of(Weskit::WML::Formatter)
    Weskit::WML::Formatter.plain.should be_kind_of(Weskit::WML::Formatter)
  end

  specify 'default formatter can be replaced' do
    default = Weskit::WML::Formatter.default
    expect { Weskit::WML::Formatter.default = Weskit::WML::Formatter.color }.to change {
      Weskit::WML::Formatter.default
    }.from(Weskit::WML::Formatter.plain).to(Weskit::WML::Formatter.color)
    Weskit::WML::Formatter.default = default
  end

  context 'plain' do
    it 'formatts attributes' do
      formatted = formatter.format Weskit::WML::Attribute.new(:foo, 'bar')
      formatted.should eq('foo=bar')

      formatted = formatter.format Weskit::WML::Attribute.new(:foo, 'bar', :code => true)
      formatted.should eq('foo=<<bar>>')

      formatted = formatter.format Weskit::WML::Attribute.new(:foo, 'bar', :translatable => true)
      formatted.should eq('foo=_"bar"')
    end

    it 'formatts elements' do
      element = Weskit::WML::Element.new :foo
      formatted = formatter.format element
      formatter.format(element).should have_same_representation_as(element)
    end
  end
end