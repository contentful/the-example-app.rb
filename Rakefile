require './bin/vendor/deploy'

namespace :heroku do
  desc 'Adds analytics for deploy'
  task :deploy do
    Deploy.append_analytics if ENV['APP_ENV'] == 'production'
  end
end

namespace :assets do
  desc 'Default task run by heroku before deploy'
  task :precompile do
    Rake::Task['heroku:deploy'].execute
  end
end
