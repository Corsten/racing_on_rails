# frozen_string_literal: true

require "rake/testtask.rb"

Rake::TestTask.new("test:acceptance") do |t|
  t.libs << "test"
  t.pattern = "tests_isolated/acceptance/**/*_test.rb"
  t.verbose = true
  t.warning = false
end

namespace :test do
  desc "Start server and run browser-based acceptance tests"
  task acceptance: ["db:test:prepare"] do
    Rake::Task["test:acceptance"].invoke
  end
end
