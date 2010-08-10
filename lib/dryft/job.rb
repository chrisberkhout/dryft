class Job

  attr_reader :id, :name, :proc, :code, :def_acts, :deps

  def initialize(db, id)
    # load from database
    @db = db
    @id = id
    load
  end
  
  def load
    @name, @code = db.get_first_row("SELECT i.name, c.code FROM jobinfo i, jobcode c WHERE i.id = c.id AND i.id = x'#{id}'")
    if @name =~ /^\<([^\/\>].*?)\>.*/
      @proc = $1
    else
      abort "ERROR: tried to initialise a job ('#{@name}') that is not a procedure."
    end
    parse
  end
  
  def reload
    load
  end
  
  protected
  
  def parse
    @actions = nil
    @def_acts = nil
    @deps = []
    stack = []
    def_start = nil
    def_end = nil

    @doc = Nokogiri::XML(@code)
    @actions = @doc.xpath("//xmlns:ActionFlow[@Name='Main Flow']/*")
    @actions.each_with_index { |a,i|
      
      comment = a.xpath("./descendant-or-self::xmlns:CommentAction/xmlns:Comment").first
      if comment && comment.inner_html =~ /^\<([^\/\>].*?)\>.*/ # opening tag

        tag = $1
        abort "ERROR: at '#{@name}:#{i+1}', attempt to define <#{@proc}> within <#{stack.last[:tag]}>." if tag == @proc && stack.length > 0
        abort "ERROR: at '#{@name}:#{i+1}', reopening <#{tag}> here implies circular dependency." if tag.is_in? stack.map{ |i| i[:tag] }
        stack.push {:tag => tag, :start => i+1 }

      elsif comment && comment.inner_html =~ /^\<\/(.*?)\>.*/ # closing tag

        tag = $1
        abort "ERROR: at '#{name}:#{i+1}', attempt to close <#{tag}> when nothing was open." if stack.length == 0
        abort "ERROR: at '#{name}:#{i+1}', attempt to close <#{tag}> when close of <#{stack.last[:tag]}> was expected." if stack.last[:tag] != tag
        if tag == @proc # end of definition of the procedure
          def_start = stack.last[:start]
          def_end   = i+1
        elsif stack.length == 1 || stack.last[:tag] == proc # end of definition of a direct dependency
          @deps.push { :proc => tag, :start => stack.last[:start], :end => i+1 }
        end
        stack.pop
        
      end
      
      # puts a.to_s
    } # each action
    
    abort "ERROR: in '#{@name}', there was no code to define the procedure <#{@proc}>." if def_start.nil?
    abort "ERROR: in '#{@name}', no closing tag for the definition of <#{@proc}>." if def_end.nil?
    abort "ERROR: in '#{@name}', the following tags were not closed: <#{stack.map{ |i| i[:tag] }.join('>, <')}>." if stack.length > 0
    
    @def_acts = @actions[ (def_start-1) .. (def_end-1) ]
    
  end # parse


  
end
