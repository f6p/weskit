require 'wml_spec_helper'

describe Weskit::WML::Root do
  include WMLHelpers

  let(:root) { Weskit::WML::Root.new }

  it_should_behave_like 'a container' do
    let(:container) { root }
  end

  it_should_behave_like 'a searchable' do
    let(:searchable) { root }
  end
end