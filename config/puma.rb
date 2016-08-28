

workers Integer(ENV['PUMA_WORKERS'] || 2)
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 8)

preload_app!

rackup      DefaultRackup

port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || ENV['HANAMI_ENV'] || 'development'

# pool ENV["DB_POOL"] || 5


before_fork do
  Hanami::Model.unload!
  # Hanami::Model.configuration.instance_variable_get('@adapter').disconnect
end


=begin
after_fork do
  Hanami::Model.load!
end
=end

on_worker_boot do
  if ENV['HANAMI_ENV'] != 'development'
    # Hanami::Model.load!
  end
end


