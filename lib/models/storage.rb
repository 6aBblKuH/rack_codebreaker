# frozen_string_literal: true

class Storage
  PATH = './lib/data/'

  def self.save_record(filename, data)
    current_file_path = file_path(filename)
    File.new(current_file_path, 'w+') unless File.exist?(current_file_path)
    File.write(current_file_path, data)
  end

  def self.load_file(filename)
    YAML.load_file(file_path(filename)) if File.exist?(file_path(filename))
  end

  def self.file_path(filename)
    "#{PATH}#{filename}.yml"
  end

  def self.save_statistic(user_id, win = true)
    data = Storage.load_file('statistic') || {}
    wins_count = data.dig(user_id, :wins_count) || 0
    wins_count += 1 if win
    data[user_id] = { wins_count: wins_count, date: Time.now }
    Storage.save_record('statistic', data.to_yaml)
  end
end
