#!/usr/bin/env ruby
# -*- coding: utf-8; mode: ruby -*-

require 'optparse'
require 'pp'
require_relative 'api'
require_relative 'common'

def fortune
  text = '今日の運勢は' + %W(大吉 中吉 小吉 吉 半吉 末吉 末小吉 凶 小凶 半凶 末凶 大凶).sample + 'だよ'
  to_string($api.rewrite(to_chainform($api.morphs(text))))
end

def build_tweet(mention)
  seeds = []
  mentions = []
  $api.sentences(mention).each do |sent|
    morphs = $api.morphs(sent)
    seeds += morphs.select {|m| m['pos'] =~ /[^代]名詞|感動詞|固有地名/ }
    mentions.push(to_chainform(morphs))
  end
  if seeds.select{ |m| m['norm_surface'] == 'みくじ' }.size > 0
    return fortune
  end

  texts = []
  scenarios = []
  5.times do
    ss = seeds.empty? ? [{ 'norm_surface' => 'BOS', 'pos' => 'BOS' }] : seeds
    ss.each do |s|
      p s
      c = $api.markov_chain(s)
      texts.push([c]) unless c.empty?
    end
  end
  mentions.each {|m| $api.trigger(m).each {|t| scenarios.push(t) } }
  seeds.each do |s|
    $api.search_tweet(s['norm_surface']).map do |t|
      texts.push($api.sentences(t.chomp).map do |sent|
                   to_chainform($api.morphs(sent))
                  end)
    end
    $api.search_reply(s['norm_surface']).map do |t|
      texts.push($api.sentences(t.chomp).map do |sent|
                   to_chainform($api.morphs(sent))
                  end)
    end
  end
  single_text = texts.sample
  p [:scenario, scenarios]
  if scenarios.size > 0 && rand(2) == 0
    p '[select scenario]'
    return scenarios.sample
  end
  single_text.map{ |a| to_string($api.rewrite(a)) }.join(' ')
end

$api = get_api(CONFIG)
name = nil
grade = nil

OptionParser.new do |opt|
  opt.on('-t BOT_NAME') {|v| name = v }
  opt.on('--grade GRADE') {|v| grade = v.to_i }
  opt.parse!(ARGV)
end

if name
  rs = $api.get_reply(name)
  STDERR.puts "grade: #{rs['grade']}"
  grade = rs['grade'] unless grade
  set_rule(grade)
  rs['replies'].each do |r|
    t = build_tweet(r['text'].rstrip)
    $api.send_reply(name, r['mention_id'], r['user_name'], t)
  end
else
  grade = 0 unless grade
  set_rule(grade)
  ARGF.each do |line|
    puts build_tweet(line.rstrip)
  end
end
