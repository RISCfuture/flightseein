if defined?(Rails) then
  Resque.redis = Flightseein::Configuration.redis.server
else
  require 'yaml'
  root = ENV['RAILS_ROOT'] || File.expand_path(File.dirname(__FILE__) + '/../..')
  env = ENV['RAILS_ENV'] || 'development'
  global_config = YAML.load_file(File.join(root, 'config', 'environments', 'common', 'redis.yml'))
  env_config = YAML.load_file(File.join(root, 'config', 'environments', env, 'redis.yml')) rescue Hash.new
  Resque.redis = global_config.merge(env_config)['server']
end
