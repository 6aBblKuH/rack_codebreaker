require 'codebreaker'
require 'digest'
require './lib/models/storage'
# require 'pry'

class Welcome

  def initialize(name, ip)
    @name = name
    @ip = ip
    # binding.pry
  end

  def log_in
    save_new_user unless old_user?
    games = Storage.load_file('games') || {}
    { user_id: @cyphered_name.to_sym, game: games[@cyphered_name] }
  end

  private

  def save_new_user
    new_user = { @cyphered_name.to_sym => @name }
    Storage.save_record('users', @users.merge(new_user).to_yaml)
  end

  def to_cypher_user_name
    @cyphered_name ||= Digest::MD5.hexdigest("#{@name}#{@ip}")
  end

  def old_user?
    @users = Storage.load_file('users') || {}
    @users.has_key?(to_cypher_user_name)
  end


end
# a = Welcome.new('test', '127.0.0.1')
