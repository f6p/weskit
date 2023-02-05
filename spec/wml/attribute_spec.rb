require 'wml_spec_helper'

describe Weskit::WML::Attribute do
  include WMLHelpers

  let(:attribute) { Weskit::WML::Attribute.new :foo, :bar }

  it 'should change code to false when setting translatable to true' do
    attribute.should_not be_code
    attribute.should_not be_translatable

    attribute.code = true
    
    attribute.should be_code
    attribute.should_not be_translatable
    
    attribute.translatable = true

    attribute.should_not be_code
    attribute.should be_translatable
  end

  it 'should change translatable to false when setting code to true' do
    attribute.should_not be_code
    attribute.should_not be_translatable

    attribute.translatable = true
    
    attribute.should_not be_code
    attribute.should be_translatable
    
    attribute.code = true

    attribute.should be_code
    attribute.should_not be_translatable
  end

  it 'should respond to predicates' do
    attr1 = attribute.dup.merge :code => true
    attr2 = attribute.dup.merge :translatable => true
    attr3 = Weskit::WML::Attribute.new :bar, "baz \n bat"

    attr1.should be_code
    attr2.should be_translatable
    attr3.should be_multiline

    attr1.should be_text
    attr2.should be_text
    attr3.should be_text
  end
end