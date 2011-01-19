module DRYFT
  class Jobs
  
    def initialize(db_file)
      abort "ERROR: The specified WinAutomation jobs database does not exist: #{db_file}" if !File.exists?(db_file)
      @job_list = get_jobs(SQLite3::Database.new db_file)
      puts "Loaded the WinAutomation jobs database from: #{db_file}"
    end

    def by_id(id)
      (@job_list.select{ |j| j.id == id }).first
    end
    def by_name(name)
      (@job_list.select{ |j| j.name == name }).first
    end
    def by_proc(proc)
      (@job_list.select{ |j| j.proc == proc }).first
    end

    def update_all
      resolve_list(@job_list).each do |j|
        j.update_from_deps(self)      
      end
      puts "Updated all procedures.\n\n"
      puts "Please PRESS F5 in the WinAutomation Console to refresh the jobs list!"
    end
  
    protected 
  
    def get_jobs(db)
      jobs = []
      rows = db.execute("SELECT hex(id) FROM jobinfo WHERE name LIKE '<%>%'")
      rows.each do |r|
        id = r[0]
        jobs.push( Job.new(db, :id => id) )
      end
      jobs
    end
  
    def resolve_list(job_list)
      resolved = []
      job_list.each{ |j| resolved = resolve(j, resolved) }
      resolved
    end
  
    def resolve(job, resolved = [], unresolved = [])
      if job.not_in? resolved
        unresolved << job
        job.deps.each do |dep|
          abort "ERROR: at '#{job.name}:#{dep[:start]}', the procedure <#{dep[:proc]}> is used but not defined." if by_proc(dep[:proc]).nil?
          if by_proc(dep[:proc]).not_in? resolved
            abort "ERROR: circular dependency detected: <#{job.proc}> -> <#{dep[:proc]}>." if by_proc(dep[:proc]).is_in? unresolved
            resolved = resolve(by_proc(dep[:proc]), resolved, unresolved)
            unresolved -= resolved
          end
        end
        resolved << job
      end
      return resolved
    end
  
  end
end # module