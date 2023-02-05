require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new 'spec'
task :default => :spec

namespace :parser do
  desc 'Re-build KPEGParser'
  task :rebuild do
    puts %x(kpeg -fsvo lib/weskit/wml/parsers/kpeg.rb lib/weskit/wml/grammars/wml.kpeg)
  end
end
