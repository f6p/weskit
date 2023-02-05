require 'wml_spec_helper'

describe Weskit::WML::Elements do
  include WMLHelpers

  let(:element)  { Weskit::WML::Element.new :foo }
  let(:elements) { Weskit::WML::Elements.new }

  it_should_behave_like 'a searchable' do
    let(:searchable) { elements }
  end

  it 'has hash like access' do
    element = Weskit::WML::Element.new(:foo).push Weskit::WML::Attribute.new(:bat, :baz)
    elements.push element

    elements[0].should be(element)
    elements[:bat].should match_value_of(:baz)
  end

  it 'store elements only' do
    expect { elements.push element }.to change { elements.size }.from(0).to(1)
    expect { elements.push :boo }.to raise_error(Weskit::WML::Errors::InvalidItem)
  end
end