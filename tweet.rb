#!/usr/bin/env ruby
# -*- coding: utf-8; mode: ruby -*-

require 'date'
require 'yaml'
require 'optparse'
require 'pp'
require_relative 'api'
require_relative 'common'

$api = get_api(CONFIG)

# Keywordを元にマルコフ連鎖してツイートを作成する
def build_tweet(keyword)
  morphs = $api.morphs(keyword)
  p ['Keyword', morphs[1]]
  to_string($api.rewrite($api.markov_chain(morphs[1])))
end

name = nil
grade = nil
keyword = nil
force = false

OptionParser.new do |opt|
  opt.on('-t BOT_NAME') {|v| name = v }
  opt.on('--grade GRADE') {|v| grade = v.to_i }
  opt.on('--keyword KEYWORD') {|v| keyword = v }
  opt.on('--force') {|v| force = v }
  opt.parse!(ARGV)
end

unless force
  if rand >= (1.0 / 12.0)
    exit 0 # ツイートタイミング調整
  end
end

if name
  rs = $api.get_reply(name)
  STDERR.puts "grade: #{rs['grade']}"
  grade = rs['grade'] unless grade
  set_rule(grade)
else
  grade = 0 unless grade
  set_rule(grade)
end

# grade=0の時75%の確率でTrendからランダムに名刺を取り出す
if keyword == nil &&  rand(100) < 75
  client = get_twitter(CONFIG)
  seeds = []
  client.local_trends(1117099).to_a.map(&:name).join('。').tap do |name|
    $api.sentences(name).each do |sent|
      morphs = $api.morphs(sent)
      seeds += morphs.select {|m| m['pos'] =~ /[^代]名詞|感動詞|固有地名/ }
    end
  end
  keyword = seeds.sample['norm_surface']
elsif keyword == nil && grade == 0
  keywords = File.read(File.expand_path(File.join(__FILE__, '..', 'keywords.txt'))).lines.map{|a|a.chomp.split(',')}.select{|a,b| Date.parse(a) == Date.today}.first
  if keywords
    keyword = keywords[1..-1].sample
  end
elsif keyword == nil && grade == 1
  keywords = File.read(File.expand_path(File.join(__FILE__, '..', 'keywords1.txt'))).strip.split(',')
  keyword = keywords.sample
elsif keyword == nil && grade == 2
  keywords = File.read(File.expand_path(File.join(__FILE__, '..', 'keywords2.txt'))).strip.split(',')
  keyword = keywords.sample
end

if keyword == nil
  exit
end

if name
  $api.send_tweet(name, build_tweet(keyword))
else
  puts build_tweet(keyword)
end
