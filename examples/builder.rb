require 'rubygems'
require 'weskit'

include Weskit::WML

unit = Root.new.build do
  unit do
    id 123
    name 'Joe'
    type :spearman

    weapon do
      name :spear
      damage 10
      description 'This is the weapon spearman usually uses.', :translatable => true
    end
  end
end

# Beware of fact that puts unit calls unit.to_ary instead of unit.to_str
# so alwas use explicit conversion if you want string representation.
puts unit.to_s
