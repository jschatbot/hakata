#!/usr/bin/env ruby
# -*- coding: utf-8; mode: ruby -*-

require 'optparse'
require 'pp'
require_relative 'api'

def to_chainform(morphs)
  morphs.map {|m| m['norm_surface'] + ':' + m['pos'] }
end

def to_string(chain)
  chain[1...-1].map {|m| m.split(/:/)[0] }.join
end

def build_tweet(mention)
  seeds = []
  mentions = []
  $api.sentences(mention).each do |sent|
    morphs = $api.morphs(sent)
    seeds += morphs.select {|m| m['pos'] =~ /[^代]名詞|感動詞|固有地名/ }
    mentions.push(to_chainform(morphs))
  end

  texts = []
  5.times do
    ss = seeds.empty? ? [{ 'norm_surface' => 'BOS', 'pos' => 'BOS' }] : seeds
    ss.each do |s|
      p s
      c = $api.markov_chain(s)
      texts.push([c]) unless c.empty?
    end
  end
  mentions.each {|m| $api.trigger(m).each {|t| texts.push(t) } }
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
  p texts
  single_text = texts.sample
  single_text.map{ |a| to_string($api.rewrite(a)) }.join(' ')
end

def set_rule(grade)
  if grade == 0
    $api.scenario_file = 'scenario_c00.txt'
    $api.rewrite_file = 'rewrite_c00.txt'
  else
    $api.scenario_file = 'scenario_c04.txt'
    $api.rewrite_file = 'rewrite_c04.txt'
  end
end

$api = API.new(ENV['JUST_URL'])
$api.basic_auth(ENV['JUST_USER'], ENV['JUST_PASSWORD']) if ENV['JUST_USER']
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
    p r
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
