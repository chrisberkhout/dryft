
require 'rubygems'
require 'sqlite3'
require 'nokogiri'

require 'ruby/object'
require 'nokogiri/node'
require 'nokogiri/node_set'

require 'dryft/job'
require 'dryft/jobs'

Jobs.new("/Users/chrisberkhout/Desktop/Jobs.dat").update_all
