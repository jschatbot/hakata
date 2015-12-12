#!/usr/bin/env ruby
# -*- coding: utf-8; mode: ruby -*-

require 'net/https'
require 'uri'
require 'json'
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
    seeds += morphs.select {|m| m['pos'] =~ /[^代]名詞/ }
    mentions.push(to_chainform(morphs))
  end

  texts = []
  5.times do
    ss = seeds.empty? ? [{ 'norm_surface' => 'BOS', 'pos' => 'BOS' }] : seeds
    ss.each do |s|
      p s
      c = $api.markov_chain(s)
      texts.push(to_string($api.rewrite(c))) unless c.empty?
    end
  end
  mentions.each {|m| $api.trigger(m).each {|t| texts.push(t) } }
  seeds.each do |s|
    $api.search_tweet(s['norm_surface']).map do |t|
      texts.push($api.sentences(t.chomp).map do |sent|
                   to_string($api.rewrite(to_chainform($api.morphs(sent))))
                  end.join(' '))
    end
    $api.search_reply(s['norm_surface']).map do |t|
      texts.push($api.sentences(t.chomp).map do |sent|
                   to_string($api.rewrite(to_chainform($api.morphs(sent))))
                  end.join(' '))
    end
  end
  p texts
  texts.sample
end

def tubo(text)
  str = []
  ret = ''
  $api.sentences(text).each do |sent|
    m = $api.morphs(sent)
    phase = -1
    m.reverse_each do |p|
      if p['pos'] == 'EOS'
        phase = 0
      elsif p['pos'] == '句点'
        phase = 0
      elsif phase == 0
        str << "つぼ"
        phase = -1
      end
      next if p['surface'] == 'EOS' || p['surface'] == 'BOS'
      str << p['surface']
    end
    ret << str.reverse.join
    str = []
  end
  ret
end

$api = API.new(ENV['JUST_URL'])
$api.basic_auth(ENV['JUST_USER'], ENV['JUST_PASSWORD']) if ENV['JUST_USER']

OptionParser.new do |opt|
  opt.on('-t BOT_NAME') {|v| $name = v }
  opt.parse!(ARGV)
end

if $name
  $api.send_tweet($name, build_tweet(''))
  rs = $api.get_reply($name)
  STDERR.puts "grade: #{rs['grade']}"
  rs['replies'].each do |r|
    t = build_tweet(r['text'].rstrip)
    $api.send_reply($name, r['mention_id'], r['user_name'], t)
  end
else
  ARGF.each do |line|
    puts build_tweet(line.rstrip)
  end
end
