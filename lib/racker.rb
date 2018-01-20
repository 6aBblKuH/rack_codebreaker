# frozen_string_literal: true

require 'erb'
require 'json'
require 'codebreaker'
Dir['./lib/models/*.rb'].each { |file| require file }

class Racker
  attr_reader :request, :helper

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @helper = Helper.new(request)
  end

  def response
    case @request.path
    when '/' then view('index')
    when '/start' then welcome
    when '/difficulty' then view('difficulty')
    when '/new_game' then new_game
    when '/game' then view('game')
    when '/guess' then guess
    when '/hint' then hint
    when '/win' then end_of_game('win')
    when '/lose' then end_of_game('lose')
    when '/statistic' then statistic
    else Rack::Response.new('Not Found', 404)
    end
  end

  private

  def welcome
    welcome = Welcome.new(request.params['name'], request.ip)
    path = welcome.log_in
    welcome_handler(welcome.data, path)
  end

  def welcome_handler(data, path)
    Rack::Response.new do |response|
      refresh_game_data(data[:game], response, data[:user_id].to_json) if data[:game]
      response.redirect(path)
    end
  end

  def new_game
    Rack::Response.new do |response|
      data = Helper.new_game_data(request.params['difficulty'].to_sym)
      refresh_game_data(data, response)
      response.redirect('/game')
    end
  end

  def guess
    user_code = request.params['user-code']
    guess = Guess.new(user_code, helper.game)
    Rack::Response.new do |response|
      if guess.current_guess
        data = helper.make_refreshed_game_data
        data[:guesses] << guess.current_guess
        refresh_game_data(data, response)
        helper.delete_cookie('validation_error', response)
      else
        response.set_cookie('validation_error', '')
      end
      response.redirect(guess.path)
    end
  end

  def hint
    Rack::Response.new do |response|
      answer = helper.game.take_a_hint!
      data = helper.make_refreshed_game_data
      data[:used_hints].push(answer)
      refresh_game_data(data, response)
      helper.delete_cookie('validation_error', response)
      response.redirect('/game')
    end
  end

  def refresh_game_data(data, response, user_id = helper.get_cookies('user_id').to_sym)
    filedata = helper.games_data
    filedata[user_id] = data
    Storage.save_record('games', filedata.to_yaml)
    response.set_cookie('game', data.to_json)
  end

  def clear_game_data(response)
    filedata = helper.games_data
    filedata[helper.get_cookies('user_id').to_sym] = nil
    Storage.save_record('games', filedata.to_yaml)
    helper.delete_cookie('game', response)
  end

  def end_of_game(result)
    Rack::Response.new(render(result)) do |response|
      clear_game_data(response)
      user_id = helper.get_cookies('user_id').to_sym
      Storage.save_statistic(user_id, result == 'win')
    end
  end

  def statistic
    @statistic = Storage.load_file('statistic')
    @users = Storage.load_file('users')
    view('statistic')
  end

  def view(template)
    Rack::Response.new(render(template))
  end

  def render(template)
    path = File.expand_path("../views/#{template}.html.erb", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
