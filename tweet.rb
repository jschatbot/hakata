#!/usr/bin/env ruby
# -*- coding: utf-8; mode: ruby -*-

require 'yaml'
require 'optparse'
require 'pp'
require_relative 'api'
require_relative 'common'

$api = API.new(ENV['JUST_URL'])
$api.basic_auth(ENV['JUST_USER'], ENV['JUST_PASSWORD']) if ENV['JUST_USER']

# Keywordを元にマルコフ連鎖してツイートを作成する
def build_tweet(keyword)
  morphs = $api.morphs(keyword)
  p ['Keyword', morphs[1]]
  to_string($api.rewrite($api.markov_chain(morphs[1])))
end

name = nil
grade = nil
keyword = nil

OptionParser.new do |opt|
  opt.on('-t BOT_NAME') {|v| name = v }
  opt.on('--grade GRADE') {|v| grade = v.to_i }
  opt.on('--keyword KEYWORD') {|v| keyword = v }
  opt.parse!(ARGV)
end

# 50%の確率でTrendからランダムに名刺を取り出す
if keyword == nil && rand(100) <= 50
  config = YAML.load(File.read(File.join(File.dirname(__FILE__), './config.yaml')))
  client = get_client(config)
  seeds = []
  client.local_trends(1117099).to_a.map(&:name).join('。').tap do |name|
    $api.sentences(name).each do |sent|
      morphs = $api.morphs(sent)
      seeds += morphs.select {|m| m['pos'] =~ /[^代]名詞|感動詞|固有地名/ }
    end
  end
  keyword = seeds.sample['norm_surface']
end

keyword ||= 'クリスマス'

if name
  rs = $api.get_reply(name)
  STDERR.puts "grade: #{rs['grade']}"
  grade = rs['grade'] unless grade
  set_rule(grade)
  $api.send_tweet(name, build_tweet(keyword))
else
  grade = 0 unless grade
  set_rule(grade)
  puts build_tweet(keyword)
end
