# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :frontend do
  desc "Build the Vue frontend"
  task :build do
    Dir.chdir(File.expand_path("frontend", __dir__)) do
      sh "npm install"
      sh "npm run build"
    end
  end
end

task :build_frontend do
  Rake::Task["frontend:build"].invoke
end
