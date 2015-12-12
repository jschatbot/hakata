#!/usr/bin/env ruby
# -*- coding: utf-8; mode: ruby -*-

require 'net/https'
require 'uri'
require 'json'

class API
  def initialize(base, proxy_host=nil, proxy_port=nil)
    @base = base
    @proxy_host = proxy_host
    @proxy_port = proxy_port
  end

  def basic_auth(user, passwd)
    @ba_user = user
    @ba_passwd = passwd
  end

  def get(method, params)
    params = URI.encode_www_form(params)
    uri = URI.parse(@base + method + '?' + params)
    req = Net::HTTP::Get.new(uri.request_uri)
    send_request(uri, req)
  end

  def post(method, body)
    uri = URI.parse(@base + method)
    req = Net::HTTP::Post.new(uri.request_uri,
                              initheader = {'Content-Type' =>'application/json', 'charset' => 'UTF-8'})
    req.body = JSON.generate(body)
    send_request(uri, req)
  end

  def send_request(uri, req)
    req.basic_auth(@ba_user, @ba_passwd) if @ba_user
    http = Net::HTTP::Proxy(@proxy_host, @proxy_port).new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 120
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = true
    res = nil
    http.start { res = http.request(req) }
    case res
    when Net::HTTPSuccess
      JSON.parse(res.body)
    else
      res.value
    end
  end

  def sentences(s)
    get('/jmat/sentence', { query: s })['sentences']
  end

  def morphs(s)
    get('/jmat/morph', { query: s })['morphs']
  end

  def markov_chain(seed)
    get('/tk/markov',
        { surface: seed['norm_surface'], pos: seed['pos'] })['morphs']
  end

  def rewrite(morphs)
    post('/tk/rewrite', { rule: 'rewrite_c04.txt', morphs: morphs })['morphs']
  end

  def trigger(morphs)
    post('/tk/trigger', { rule: 'scenario_c04.txt', morphs: morphs })['texts']
  end

  def search_tweet(query)
    get('/search/tweet', { query: query, limit: 3 })['texts']
  end

  def search_reply(query)
    get('/search/reply', { query: query, limit: 3 })['texts']
  end

  def get_reply(name)
    get('/tweet/get_reply', { bot_name: name })
  end

  def send_tweet(name, message)
    post('/tweet/simple',
         { bot_name: name, message: message })['result'] == 'true'
  end

  def send_reply(name, mention_id, user_name, message)
    post('/tweet/send_reply',
         { bot_name: name,
           replies: [ { mention_id: mention_id, user_name: user_name,
                        message: message } ] })[0] == 'true'
  end
end
