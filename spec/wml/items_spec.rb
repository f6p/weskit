require 'wml_spec_helper'

describe Weskit::WML::Items do
  include WMLHelpers

  let(:items) { Weskit::WML::Items.new }

  it_should_behave_like 'a container' do
    let(:container) { items }
  end

  it 'has contents formatter' do
    expect { items.formatter = Weskit::WML::Formatter.color }.to change { items.formatter }.from(Weskit::WML::Formatter.default).to(Weskit::WML::Formatter.color)
  end
end