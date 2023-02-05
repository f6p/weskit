require 'rubygems'
require 'weskit'

include Weskit::WML

# Compared to builder example this one uses more
# conservative approach to WML creation process.

object  = Element.new :object
object << Attribute.new(:name, 'orb')
object << Attribute.new(:type, 'magic item')

modification  = Element.new :modification
modification << Attribute.new(:hp, 100)

object << modification

# Set differend formatter globally.
Formatter.default = Formatter.color

puts object.to_s
