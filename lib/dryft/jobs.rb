class Jobs
  
  def initialize(db_file)
    @db = SQLite3::Database.new db_file
    @job_list = get_jobs
    
    puts resolve_order_all(@job_list,self).map{|j|j.name}.join("\n")
    # resolve_order_all(@job_list,self)
    
  end

  def by_id(id)
    (@job_list.select{ |j| j.id == id })[0]
  end
  def by_name(name)
    (@job_list.select{ |j| j.name == name })[0]
  end
  def by_proc(proc)
    (@job_list.select{ |j| j.proc == proc })[0]
  end
  
  protected 
  
  def get_jobs
    jobs = []
    rows = @db.execute("SELECT hex(id) FROM jobinfo WHERE name LIKE '<%>%'")
    rows.each { |r|
      id = r[0]
      jobs.push( Job.new(@db, :id => id) )
    }
    jobs
  end
  
  def resolve_order_all(job_list, jobs)
    order = []
    job_list.each{ |j|
      order = resolve_order(j, self, order)
    }
    order
  end
  
  def resolve_order(job, jobs, resolved, unresolved = [])
    if job.not_in? resolved
      unresolved << job
      job.deps.each { |dep|
        abort "ERROR: at '#{job.name}:#{dep[:start]}', the procedure <#{dep.proc}> is used but not defined." if jobs.by_proc(dep[:proc]).nil?
        if jobs.by_proc(dep[:proc]).not_in? resolved
          abort "ERROR: circular dependency detected: <#{job.proc}> -> <#{dep.proc}>." if jobs.by_proc(dep[:proc]).is_in? unresolved
          resolved = resolve_order(jobs.by_proc(dep[:proc]), jobs, resolved, unresolved)
          unresolved -= resolved
        end
      }
      resolved << job
    end
    return resolved
  end
  
  
  
end