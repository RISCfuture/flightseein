#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Flightseein::Application.load_tasks

if Rails.env.development? then
    require 'yard'
    YARD::Rake::YardocTask.new do |doc|
      doc.options << '-m' << 'markdown' << '-M' << 'redcarpet'
      doc.options << '--protected' << '--no-private'
      doc.options << '-r' << 'doc/README_FOR_APP.md'
      doc.options << '-o' << 'doc/app'
      doc.options << '--title' << "flightseein' Documentation'"

      doc.files = [ 'app/**/*.rb', 'lib/**/*.rb', 'doc/README_FOR_APP.md' ]
    end
end
