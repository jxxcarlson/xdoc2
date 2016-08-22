require 'rake'
require 'hanami/rake_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.libs    << 'spec'
end

task default: :test
task spec: :test

desc "Make backup at Heroku and download it to 'latest.dump'"
task :get_backup do
  `heroku pg:backups capture`
  system("curl -o latest.dump `heroku pg:backups public-url`")
end

