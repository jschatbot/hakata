require 'twitter'

def get_client(config)
  Twitter::REST::Client.new do |c|
    config['twitter'].each do |key,value|
      c.__send__(key + '=', value)
    end
  end
end

def set_rule(grade)
  if grade == 0
    $api.scenario_file = 'scenario_c00.txt'
    $api.rewrite_file = '3_rewrite_grade0.txt'
  elsif grade == 1
    $api.scenario_file = 'scenario_c04.txt'
    $api.rewrite_file = 'rewrite_c04.txt'
  else
    $api.scenario_file = 'scenario_c04.txt'
    $api.rewrite_file = '3_rewrite_grade2.txt'
  end
end

def to_chainform(morphs)
  morphs.map {|m| m['norm_surface'] + ':' + m['pos'] }
end

def to_string(chain)
  chain[1...-1].map {|m| m.split(/:/)[0] }.join
end
