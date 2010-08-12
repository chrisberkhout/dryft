class Nokogiri::XML::Node

  def equivalent_to?(other)

    self_nodes  = []
    other_nodes = []
    
    self.traverse  { |n| self_nodes  << n }
    other.traverse { |n| other_nodes << n }
    
    return false if self_nodes.length != other_nodes.length
    
    0.upto(self_nodes.length-1) { |i|

      s = self_nodes[i]  ; s_attribs = {} ; s.attributes.each_pair { |k,v| s_attribs[k] = v.value }
      o = other_nodes[i] ; o_attribs = {} ; o.attributes.each_pair { |k,v| o_attribs[k] = v.value }

      return false if s.name != o.name
      return false if ((s.text? || s.cdata?) && s.text) != ((o.text? || o.cdata?) && o.text)
      return false if s_attribs != o_attribs

    }
    
    return true
    
  end
  
  def not_equivalent_to?(other)
    !equivalent_to?(other)
  end
  
end
