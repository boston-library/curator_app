# frozen_string_literal: true

require_relative '../scripts'

namespace :curator_app do
  desc 'Verify data migrated from Commonwealth/Fedora'
  task :verify, [:csv_path] => [:environment] do |_t, args|
    raise "No csv found at #{args[:csv_path]}!" if !File.file?(args[:csv_path])

    Scripts.verify_migration(args[:csv_path])
  end
end
