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
