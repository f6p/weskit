class Object
  include ::Weskit::WML::Mixins::Validator

  attr_reader :attribute

  alias_method :attr, :attribute

  def attribute= item
    @attribute = item ? (raise_unless ::Weskit::WML::Attribute, item ; item) : nil
  end

  alias_method :attr=, :attribute=

  def attribute?
    @attribute ? true : false
  end

  alias_method :attr?, :attribute?
end
