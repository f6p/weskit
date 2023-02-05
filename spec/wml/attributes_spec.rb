require 'wml_spec_helper'

describe Weskit::WML::Attributes do
  include WMLHelpers

  let(:attribute)  { Weskit::WML::Attribute.new :foo, :bar }
  let(:attributes) { Weskit::WML::Attributes.new }

  it 'has hash like access' do
    attributes << attribute
    attributes[:foo].should match_value_of(:bar)
    attributes[:foo].attribute.should have_same_representation_as(attribute)
  end

  it 'store attributes only' do
    expect { attributes.push attribute }.to change { attributes.size }.from(0).to(1)
    expect { attributes.push :boo }.to raise_error(Weskit::WML::Errors::InvalidItem)
  end
end