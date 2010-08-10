class Object
  def is_in?(array)
    array.include?(self)
  end
  def not_in?(array)
    !array.include?(self)
  end
end
