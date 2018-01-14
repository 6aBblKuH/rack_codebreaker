require 'erb'
require 'json'
require 'codebreaker'
require './lib/models/storage'
Dir['./lib/models/*.rb'].each { |file| require file }


class Racker
  attr_reader :request

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
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
    when '/win' then win
    when '/lose' then lose
    else Rack::Response.new('Not Found', 404)
    end
  end

  private
  def welcome
    data = Welcome.new(@request.params['name'], @request.ip).log_in
    welcome_handler(data)
  end

  def welcome_handler(data)
    Rack::Response.new do |response|
      response.set_cookie('user_id', data[:user_id].to_json)
      path = if data[:game]
        refresh_game_data(data[:game], response, data[:user_id])
        '/game'
      else
        '/difficulty'
      end
      response.redirect(path)
    end
  end

  def new_game
    Rack::Response.new do |response|
      data = new_game_data(@request.params['difficulty'].to_sym)
      refresh_game_data(data, response)
      response.redirect('/game')
    end
  end

  def guess
    @user_code = @request.params['user-code']
    game.valid_answer?(@user_code) ? handle_guess : invalid_input
  end

  def handle_guess
    Rack::Response.new do |response|
      path = if win?
        '/win'
      elsif game.attempts > 1
        current_guess = { user_code: @user_code, match: game.handle_guess(@user_code) }
        data = make_refreshed_game_data
        data[:guesses] << current_guess
        refresh_game_data(data, response)
        '/game'
      else
        '/lose'
      end
      delete_cookie('validation_error', response)
      response.redirect(path)
    end
  end

  def invalid_input
    Rack::Response.new do |response|
      response.set_cookie('validation_error', '')
      response.redirect('/game')
    end
  end

  def hint
    Rack::Response.new do |response|
      answer = game.take_a_hint!
      data = make_refreshed_game_data
      data[:used_hints].push(answer)
      refresh_game_data(data, response)
      delete_cookie('validation_error', response)
      response.redirect('/game')
    end
  end

  def render(template)
    path = File.expand_path("../views/#{template}.html.erb", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

  def view(template)
    Rack::Response.new(render(template))
  end

  def new_game_data(difficulty)
    data = Codebreaker::Game.generate_game_data(difficulty)
    data[:secret_code] = data.default
    data
  end

  def refresh_game_data(data, response, user_id = get_cookies('user_id').to_sym)
    filedata = games_data
    filedata[user_id] = data
    Storage.save_record('games', filedata.to_yaml )
    response.set_cookie('game', data.to_json)
  end

  def clear_game_data(response)
    filedata = games_data
    filedata[get_cookies('user_id').to_sym] = nil
    Storage.save_record('games', filedata.to_yaml )
    delete_cookie('game', response)
  end

  def make_refreshed_game_data
    { secret_code: game.secret_code, attempts: game.attempts, hints: game.hints, used_hints: used_hints, guesses: guesses }
  end

  def decode_data_from_request(name)
    JSON.parse(@request.cookies[name])
  end

  def game_data
    decode_data_from_request('game')
  end

  def games_data
    Storage.load_file('games') || {}
  end

  def get_cookies(name)
    @request.cookies[name] ? decode_data_from_request(name) : nil
  end

  def delete_cookie(name, response)
    response.delete_cookie(name) if @request.cookies[name]
  end

  def guesses
    game_data['guesses'] || []
  end

  def used_hints
    game_data['used_hints'] || []
  end

  def game
    @game ||= Codebreaker::Game.new(game_data['secret_code'], game_data['attempts'], game_data['hints'])
  end

  def win?
    game.equal_codes?(@user_code)
  end

  def win
    Rack::Response.new(render('win')) do |response|
      clear_game_data(response)
    end
  end

  def lose
    Rack::Response.new(render('lose')) do |response|
      clear_game_data(response)
    end
  end

  def save_statistic
    old_data = Storage.load_file('statistic') || {}
    user_id = get_cookies(user_id).to_sym
    old_wins_count = old_data.dig(user_id, :wins_count) || 0
    data[user_id] = { wins_count: old_wins_count + 1, date: Time.now }
    Storage.save_record('statistic', data.to_yaml)
  end

end
