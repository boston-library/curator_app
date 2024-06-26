# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
rails_env = ENV.fetch('RAILS_ENV') { 'development' }
max_threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
app_dir = File.expand_path('..', __dir__)

threads min_threads_count, max_threads_count
workers ENV.fetch('WEB_CONCURRENCY') { 2 }

environment rails_env

worker_timeout 3600 if rails_env == 'development'

preload_app!
# New feature that reduces latency https://github.com/puma/puma/blob/master/5.0-Upgrade.md#lower-latency-better-throughput
wait_for_less_busy_worker 0.002

on_restart do
   puts "Refreshing Gemfile at #{app_dir}/Gemfile"
   ENV['BUNDLE_GEMFILE'] = "#{app_dir}/Gemfile"
end

# Best Practice is to reconnect any Non Active Record Connections on boot in clustered mode
on_worker_boot do
  puts 'Extablishing Active Record Connection...'
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end

  if defined?(Curator)
    puts 'Reloading Remote Service Connection Pools...'
    Curator::Services::RemoteService.reload!
  end
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect!

  if defined?(Curator)
    Curator::Services::RemoteService.clear!
  end
end

if %w(staging production).member?(rails_env)
  bind "unix://#{app_dir}/tmp/sockets/curator_api_puma.sock"
  stdout_redirect("#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true)
  pidfile "#{app_dir}/tmp/pids/curator_puma_server.pid"
  state_path "#{app_dir}/tmp/pids/curator_puma_server.state"
  activate_control_app "unix://#{app_dir}/tmp/sockets/curator_pumactl.sock"
else
  port 3000
  stdout_redirect('/dev/stdout', '/dev/stderr')
  pidfile "#{app_dir}/tmp/pids/server.pid"
  state_path "#{app_dir}/tmp/pids/server.state"
  plugin :tmp_restart
end
