require 'wml_spec_helper'

describe Weskit::WML::Item do
  include WMLHelpers

  let(:item) { Weskit::WML::Item.new :foo }

  it 'should compare items by name or class' do
    bat = Weskit::WML::Item.new :bat

    (item <=> bat).should eq(1)
    (bat <=> item).should eq(-1)

    bat = Weskit::WML::Element.new :bat

    (item <=> bat).should eq(1)
    (bat <=> item).should eq(-1)

    (item <=> :bat).should be_nil
  end

  it 'should have name that is identifier' do
    item.should have_identifier_of(:foo)
  end
end