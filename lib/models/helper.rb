# frozen_string_literal: true

class Helper
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def self.new_game_data(difficulty)
    data = Codebreaker::Game.generate_game_data(difficulty)
    data[:secret_code] = data.default
    data
  end

  def make_refreshed_game_data
    { secret_code: game.secret_code, attempts: game.attempts, hints: game.hints, used_hints: used_hints, guesses: guesses }
  end

  def decode_data_from_request(name)
    JSON.parse(request.cookies[name])
  end

  def game_data
    decode_data_from_request('game')
  end

  def games_data
    Storage.load_file('games') || {}
  end

  def get_cookies(name)
    request.cookies[name] ? decode_data_from_request(name) : nil
  end

  def delete_cookie(name, response)
    response.delete_cookie(name) if request.cookies[name]
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
end
