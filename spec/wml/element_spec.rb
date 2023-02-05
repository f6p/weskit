require 'wml_spec_helper'

describe Weskit::WML::Element do
  include WMLHelpers

  let(:element) { Weskit::WML::Element.new :foo }

  it_should_behave_like 'a container' do
    let(:container) { element }
  end

  it_should_behave_like 'a searchable' do
    let(:searchable) { element }
  end

  it 'can be amending element' do
    element = Weskit::WML::Element.new :foo, :amendment => true
    element.should be_amendment
  end
end