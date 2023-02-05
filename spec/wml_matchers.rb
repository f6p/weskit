RSpec::Matchers.define :have_identifier_of do |name|
  match do |actual|
    actual.name == Weskit::WML::Item.identifier(name)
  end
end

RSpec::Matchers.define :have_same_representation_as do |other|
  match do |actual|
    actual.to_s == other.to_s
  end
end

RSpec::Matchers.define :match_value_of do |value|
  match do |actual|
    actual.to_s == value.to_s
  end
end