require 'codebreaker'
require 'digest'
require './lib/models/storage'

class Welcome

  def initialize(name, ip)
    @name = name
    @ip = ip
  end

  def log_in
    save_new_user unless old_user?
    games = dataOrHash('games')
    { user_id: @cyphered_name, game: games[@cyphered_name] }
  end

  private

  def save_new_user
    new_user = { @cyphered_name => @name }
    Storage.save_record('users', @users.merge(new_user).to_yaml)
  end

  def to_cypher_user_name
    @cyphered_name ||= Digest::MD5.hexdigest("#{@name}#{@ip}").to_sym
  end

  def old_user?
    @users = dataOrHash('users')
    @users.has_key?(to_cypher_user_name)
  end

  def dataOrHash(name)
    Storage.load_file(name) || {}
  end
end
