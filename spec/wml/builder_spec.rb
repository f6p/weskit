require 'wml_spec_helper'

describe Weskit::WML::Builder do
  include WMLHelpers

  let(:element) { Weskit::WML::Element.new :foo }

  specify 'builds attributes' do
    reference = Weskit::WML::Element.new(:foo)                 \
      << Weskit::WML::Attribute.new(:bar, :foo)                \
      << Weskit::WML::Attribute.new(:baz, :foo, :code => true) \
      << Weskit::WML::Attribute.new(:bat, :foo, :translatable => true)

    element.build do
      bar :foo
      baz :foo, :code => true
      bat :foo, :translatable => true
    end

    element.should have_same_representation_as(reference)
  end

  specify 'builds elements' do
    reference = Weskit::WML::Element.new(:foo) \
      << Weskit::WML::Element.new(:baz)        \
      << Weskit::WML::Element.new(:bar)        \
      << sample_amendment

    element.build do
      baz {}
      bar {}
      bar :amendment => true do
        bat :baz
      end
    end

    element.should have_same_representation_as(reference)
  end

  specify 'convert hashes' do
    hash = {
      :a => :foo,
      :b => {
        :c => :bar
      }
    }

    converted = Weskit::WML::Builder.convert hash
    converted[:a].should match_value_of(:foo)
    converted.elements[:c].should match_value_of(:bar)
  end
end