# frozen_string_literal: true

require 'codebreaker'
require 'digest'
require './lib/models/storage'

class Welcome
  attr_reader :data, :path

  def initialize(name, ip)
    @name = name
    @ip = ip
  end


  def log_in
    save_new_user unless old_user?
    games = data_or_hash('games')
    @data = { user_id: @cyphered_name, game: games[@cyphered_name] }
    @path = data[:game] ? '/game' : '/difficulty'
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
    @users = data_or_hash('users')
    @users.key?(to_cypher_user_name)
  end

  def data_or_hash(name)
    Storage.load_file(name) || {}
  end
end
