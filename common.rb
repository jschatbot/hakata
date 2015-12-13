require 'twitter'
require 'yaml'

def get_api(config)
  api = API.new(config['api']['url'])
  api.basic_auth(config['api']['basic_user'], config['api']['basic_password']) if config['api']['basic_user']
  api
end

def get_twitter(config)
  Twitter::REST::Client.new do |c|
    config['twitter'].each do |key,value|
      c.__send__(key + '=', value)
    end
    c.connection_options[:proxy] = CONFIG['proxy'] if CONFIG['proxy']
  end
end

def set_rule(grade)
  if grade == 0
    $api.scenario_file = '3_scenario_grade0.txt'
    $api.rewrite_file = '3_rewrite_grade0.txt'
  elsif grade == 1
    $api.scenario_file = '3_scenario_grade1.txt'
    $api.rewrite_file = '3_rewrite_grade1.txt'
  else
    $api.scenario_file = '3_scenario_grade2.txt'
    $api.rewrite_file = '3_rewrite_grade2.txt'
  end
end

def to_chainform(morphs)
  morphs.map {|m| m['norm_surface'] + ':' + m['pos'] }
end

def to_string(chain)
  chain[1...-1].map {|m| m.split(/:/)[0] }.join
end

CONFIG = YAML.load(File.read(File.join(File.dirname(__FILE__), './config.yaml')))
