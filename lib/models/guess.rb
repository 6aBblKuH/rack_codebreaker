# frozen_string_literal: true

class Guess
  attr_reader :path, :current_guess

  def initialize(user_code, game)
    @user_code = user_code
    @game = game
    @path = @game.valid_answer?(@user_code) ? handle_guess : '/game'
  end

  private

  def handle_guess
    if win?
      '/win'
    elsif @game.attempts > 1
      @current_guess = { user_code: @user_code, match: @game.handle_guess(@user_code) }
      '/game'
    else
      '/lose'
    end
  end

  def win?
    @game.equal_codes?(@user_code)
  end
end
