module DRYFT
  class Job

    attr_reader :id, :name, :proc, :def_acts, :deps

    def initialize(db, info)
      @db = db
      @id = get_id(db, info)
      load
    end
  
    def reload
      load
    end
  
    def update_from_deps(jobs)
      no_change = true
      @deps.each do |dep|
        src_job = jobs.by_proc(dep[:proc])
        if dep[:acts].not_equivalent_to?( src_job.def_acts )
          no_change = false
          dep[:acts].after( src_job.def_acts.to_xml )
          dep[:acts].unlink
          puts "At #{@name}:#{dep[:start]}, updated procedure <#{dep[:proc]}> from its definition."
        end
      end
      if no_change
        puts "No change to '#{@name}'."
      else
        updated_code = @doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        @db.execute("UPDATE jobcode SET code = ? WHERE hex(id) = ?", [updated_code, @id])

        # Switch to a new job ID, because there is no way to trigger a reload ov the original job ID's code.
        new_id = @db.execute("SELECT HEX(RANDOMBLOB(LENGTH(Id))) FROM jobcode")[0][0]
        @db.execute("UPDATE compilerproperties SET JobId = x'#{new_id}' WHERE hex(JobId) = ?", [@id])
        @db.execute("UPDATE jobaddon SET JobId = x'#{new_id}' WHERE hex(JobId) = ?", [@id])
        @db.execute("UPDATE jobaddonassembly SET JobId = x'#{new_id}' WHERE hex(JobId) = ?", [@id])
        @db.execute("UPDATE jobattachment SET JobId = x'#{new_id}' WHERE hex(JobId) = ?", [@id])
        @db.execute("UPDATE jobcode SET Id = x'#{new_id}' WHERE hex(Id) = ?", [@id])
        @db.execute("UPDATE jobinfo SET Id = x'#{new_id}' WHERE hex(Id) = ?", [@id])
        @db.execute("UPDATE jobproperties SET Id = x'#{new_id}' WHERE hex(Id) = ?", [@id])
        @db.execute("UPDATE jobproperties2 SET Id = x'#{new_id}' WHERE hex(Id) = ?", [@id])
        @db.execute("UPDATE triggers SET JobId = x'#{new_id}' WHERE hex(JobId) = ?", [@id])
        @id = new_id

        reload
      end
    end
  
    protected
  
    def get_id(db, info)
      case info.keys[0]
      when :id
        info[:id]
      when :name
        rows = db.execute("SELECT hex(id) FROM jobinfo WHERE name = ?", [info[:name]])
        abort "ERROR: tried to load the job named '#{info[:name]}', but that name is not unique." if rows.length > 1
        abort "ERROR: tried to load the job named '#{info[:name]}', but it was not found." if rows.length == 0
        rows[0][0]
      when :proc
        rows = db.execute("SELECT hex(id) FROM jobinfo WHERE name LIKE ?", ["<#{info[:proc]}>%"])
        abort "ERROR: tried to load the procedure named '#{info[:proc]}', but that name is not unique." if rows.length > 1
        abort "ERROR: tried to load the procedure named '#{info[:proc]}', but it was not found." if rows.length == 0
        rows[0][0]
      end
    end
  
    def load
      rows = @db.execute("SELECT hex(i.id), i.name, c.code FROM jobinfo i, jobcode c WHERE i.id = c.id AND hex(i.id) = ?", [@id])
      abort "ERROR: tried to load the job with ID '#{@id}', but it was not found." if rows.length == 0
      @id, @name, @code = rows[0]
      if @name =~ /^\<([^\/\>].*?)\>.*/
        @proc = $1
      else
        abort "ERROR: tried to initialise a job ('#{@name}') that is not a procedure."
      end
      parse
    end
  
    def parse
      @actions = nil
      @def_acts = nil
      @deps = []
      stack = []
      def_start = nil
      def_end = nil

      @doc = Nokogiri::XML(@code)
      @actions = @doc.xpath("//xmlns:ActionFlow[@Name='Main Flow']/*")
      @actions.each_with_index do |a,i|
      
        comment = a.xpath("./descendant-or-self::xmlns:CommentAction/xmlns:Comment").first
        if comment && comment.inner_text =~ /^\<([^\/\>].*?)\>.*/ # opening tag

          tag = $1
          abort "ERROR: at '#{@name}:#{i+1}', attempt to define <#{@proc}> within <#{stack.last[:tag]}>." if tag == @proc && stack.length > 0
          abort "ERROR: at '#{@name}:#{i+1}', reopening <#{tag}> here implies circular dependency." if tag.is_in? stack.map{ |e| e[:tag] }
          stack.push({:tag => tag, :start => (i+1) })

        elsif comment && comment.inner_text =~ /^\<\/(.*?)\>.*/ # closing tag

          tag = $1
          abort "ERROR: at '#{name}:#{i+1}', attempt to close <#{tag}> when nothing was open." if stack.length == 0
          abort "ERROR: at '#{name}:#{i+1}', attempt to close <#{tag}> when close of <#{stack.last[:tag]}> was expected." if stack.last[:tag] != tag
          if tag == @proc # end of definition of the procedure
            def_start = stack.last[:start]
            def_end   = i+1
          elsif stack.length == 1 || stack[-2][:tag] == @proc # end of definition of a direct dependency
            @deps.push({ :proc => tag, :start => stack.last[:start], :end => i+1, :acts => @actions[(stack.last[:start]-1)..(i)] })
          end
          stack.pop

        end
      
      end # each action
    
      abort "ERROR: in '#{@name}', there was no code to define the procedure <#{@proc}>." if def_start.nil?
      abort "ERROR: in '#{@name}', no closing tag for the definition of <#{@proc}>." if def_end.nil?
      abort "ERROR: in '#{@name}', the following tags were not closed: <#{stack.map{ |e| e[:tag] }.join('>, <')}>." if stack.length > 0
    
      @def_acts = @actions[ (def_start-1) .. (def_end-1) ]
    end # parse

  end
end # module
