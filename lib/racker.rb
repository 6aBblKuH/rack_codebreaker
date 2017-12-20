require 'erb'
require 'json'
require 'codebreaker'

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
    when '/' then Rack::Response.new(render('index'))
    when '/start'
      Rack::Response.new(render('difficulty'))
    when '/difficulty'
      Rack::Response.new do |response|
        refresh_game_data(new_game(@request.params['difficulty'].to_sym), response)
        response.redirect('/game')
      end
    when '/game' then Rack::Response.new(render('game'))
    when '/guess'
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
    when '/win' then Rack::Response.new(render('win'))
    when '/lose' then Rack::Response.new(render('lose'))
    else Rack::Response.new('Not Found', 404)
    end
  end

  def game_data
    JSON.parse(@request.cookies['game'])
  end

  def round_answer
    @request.cookies['round_answer'] ? JSON.parse(@request.cookies['round_answer']) : ''
  end

  private
  def render(template)
    path = File.expand_path("../views/#{template}.html.erb", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

  def new_game(difficulty)
    data = Codebreaker::Game.generate_game_data(difficulty)
    data[:secret_code] = data.default
    data.to_json
  end

  def refresh_game_data(data, response)
    response.set_cookie('game', data)
  end

  def make_refreshed_game_data
    { secret_code: game.secret_code, attempts: game.attempts, hints: game.hints }.to_json
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
