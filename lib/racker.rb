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
    when '/win' then view('win')
    when '/lose' then view('lose')
    else Rack::Response.new('Not Found', 404)
    end
  end

  def welcome
    data = Welcome.new(@request.params['name'], @request.ip).log_in
    data[:game] ? continue_game(data) : start_new(data[:user_id])
  end

  def game_data
    decode_data_from_request('game')
  end

  def continue_game(data)
    Rack::Response.new do |response|
      refresh_game_data(data[:game].to_json, response)
      response.redirect('/game')
    end
  end

  def start_new(user_id)
    Rack::Response.new do |response|
      response.set_cookie('user_id', user_id.to_json)
      response.redirect('/difficulty')
    end
  end

  def round_answer
    @request.cookies['round_answer'] ? decode_data_from_request('round_answer') : ''
  end

  def guess
    Rack::Response.new do |response|
      @user_code = @request.params['user-code']
      if win?
        response.redirect('/win')
      else
        response.set_cookie('round_answer', game.handle_guess(@user_code).to_json)
        refresh_game_data(make_refreshed_game_data, response)
        path = game.attempts.zero? ? '/lose' : '/game'
        response.redirect(path)
      end
    end
  end

  def new_game
    Rack::Response.new do |response|
      data = new_game_data(@request.params['difficulty'].to_sym)
      filedata = Storage.load_file('games') || {}
      filedata[decode_data_from_request('user_id')] = data
      Storage.save_record('games', filedata.to_yaml )
      refresh_game_data(data.to_json, response)
      response.redirect('/game')
    end
  end

  def hint
    Rack::Response.new do |response|
      # answer = game.hints.empty? ? 'You have not hints anymore' : game.take_a_hint!

    end
  end

  private
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

  def refresh_game_data(data, response)
    response.set_cookie('game', data)
  end

  def make_refreshed_game_data
    { secret_code: game.secret_code, attempts: game.attempts, hints: game.hints }.to_json
  end

  def decode_data_from_request(name)
    JSON.parse(@request.cookies[name])
  end

  def game
    @game ||= Codebreaker::Game.new(game_data['secret_code'], game_data['attempts'], game_data['hints'])
  end

  def win?
    game.equal_codes?(@user_code)
  end

  def lose?

  end

end
