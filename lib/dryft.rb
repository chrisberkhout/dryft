
require 'rubygems'
require 'sqlite3'
require 'nokogiri'

require 'ruby/object'



# db = SQLite3::Database.new "/Users/chrisberkhout/Projects/matholroyd/dryft-data/Jobs.dat"
db = SQLite3::Database.new "/Users/chrisberkhout/Desktop/Jobs.dat"

proc_info = {}
db.execute("SELECT hex(i.id), i.name, c.code FROM jobinfo i, jobcode c WHERE i.id = c.id") { |id,name,code_xml|

  if name =~ /^\<([^\/\>].*?)\>.*/ # job is a procedure
    proc = $1
    
    abort "ERROR: multiple jobs for definition of procedure '<#{proc}>'!" if !proc_info[proc].nil?
    proc_info[proc] = { :id => id, :def => {}, :deps => {} }
    tag_stack = []

    code = Nokogiri::XML(code_xml)
    actions = code.xpath("//xmlns:ActionFlow[@Name='Main Flow']/*")
    actions.each_with_index { |a,i|
      
      comment = a.xpath("./descendant-or-self::xmlns:CommentAction/xmlns:Comment").first
      
      if comment && comment.inner_html =~ /^\<([^\/\>].*?)\>.*/ # opening tag
        tag = $1
        
        abort "ERROR: at '#{name}:#{i+1}', reopening <#{tag}> here implies circuar dependency." if tag.is_in? tag_stack
        if tag == proc # start of definition of the procedure
          abort "ERROR: at '#{name}:#{i+1}', attempt to define <#{proc}> within <#{tag_stack.last}>." if tag_stack.length > 0
          proc_info[proc][:def][:start] = i+1
          # puts "INFO: start of definition of procedure <#{proc}>."
        elsif tag_stack.length == 0 || tag_stack.last == proc # start of definition of a direct dependency
          proc_info[proc][:deps][tag] = { :start => i+1 }
          # puts "INFO: start of definition of direct dependency <#{tag}>."
        else
          # puts "INFO: start of definition of in-direct dependency <#{tag}>."
        end
    
        tag_stack.push tag
        
      elsif comment && comment.inner_html =~ /^\<\/(.*?)\>.*/ # closing tag
        tag = $1
        abort "ERROR: at '#{name}:#{i+1}', attempt to close <#{tag}> when nothing was open." if tag_stack.length == 0
        abort "ERROR: at '#{name}:#{i+1}', attempt to close <#{tag}> when close of <#{tag_stack.last}> was expected." if tag_stack.last != tag
        tag_stack.pop
        
        if tag == proc # end of definition of the procedure
          proc_info[proc][:def][:end] = i+1
          # puts "INFO: end of definition of procedure <#{proc}>."
        elsif tag_stack.length == 0 || tag_stack.last == proc # end of definition of a direct dependency
          proc_info[proc][:deps][tag][:end] = i+1
          # puts "INFO: end of definition of direct dependency <#{tag}>."
        else
          # puts "INFO: end of definition of in-direct dependency <#{tag}>."
        end
        
      end
      
      # puts a.to_s
      
    } # each action
    
    abort "ERROR: the job named '#{name}' doesn't contain code to define the procedure <#{proc}>." if proc_info[proc][:def][:start].nil?
    abort "ERROR: in '#{name}', the following tags were not closed: <#{tag_stack.join('>, <')}>." if tag_stack.length > 0
    abort "ERROR: in '#{name}', no closing tag for the definition of <#{proc}>." if proc_info[proc][:def][:end].nil?

  end # job is a procedure
  
} # db.execute

puts proc_info.to_yaml


def resolve_order_all(proc_info)
  proc_info[:all] = { :deps => {} }
  (proc_info.keys - [:all]).each { |p| proc_info[:all][:deps][p] = {} } 
  return resolve_order(:all, proc_info, [], []) - [:all]
end


def resolve_order(name, proc_info, resolved, unresolved)
  unresolved << name
  proc_info[name][:deps].each_pair { |dep_name,dep_info|
    abort "ERROR: at '<#{name}>:#{dep_info[:start]}', the procedure <#{dep_name}> is used but not defined." if proc_info[dep_name].nil?
    if dep_name.not_in? resolved
      abort "ERROR: circular dependency detected: <#{name}> -> <#{dep_name}>." if dep_name.is_in? unresolved
      resolved = resolve_order(dep_name, proc_info, resolved, unresolved)
      unresolved -= resolved
    end
  }
  return resolved << name
end

order = resolve_order_all(proc_info)
puts order.to_yaml

order.each { |proc|
  
  code_xml = db.get_first_value("SELECT code FROM jobcode WHERE id = x'#{proc_info[proc][:id]}'")
  puts "***** loaded #{proc} *****"
  
  proc_info[proc][:deps].each_pair { |dep_name,dep_info|
    dep_xml = db.get_first_value("SELECT code FROM jobcode WHERE id = x'#{proc_info[dep_name][:id]}'")
    puts "***** loaded DEP_XML for #{dep_name} *****"
    
    
  }

}






# TODO:
#   - add diff between job name and proc name
# - function to actually do the updates back to the DB.
#
# - make proc_info and resolution funcs into an object?



# def resolve(proc, resolved, unresolved):
#    unresolved.append(proc)
#    for dep in proc.deps:
#       if dep not in resolved:
#          if dep in unresolved:
#             raise Exception('Circular reference detected: %s -> %s' % (node.name, edge.name))
#          resolve(proc, resolved, unresolved)
#    resolved.append(proc)
#    unresolved.remove(proc)

# http://www.electricmonk.nl/log/2008/08/07/dependency-resolving-algorithm/