class Nokogiri::XML::NodeSet 
  
  def equivalent_to?(other)
    return false if self.length != other.length
    0.upto(self.length-1) { |i| return false if self[i].not_equivalent_to?( other[i] ) }
    return true
  end
  
  def not_equivalent_to?(other)
    !equivalent_to?(other)
  end
  
end
