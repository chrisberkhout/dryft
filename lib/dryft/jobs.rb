class Jobs
  def initialize(db_file)
    @db = SQLite3::Database.new db_file
    
  end
  
  # def load_jobs
  #   @job_list = 
  #   
  # end
  
  
end