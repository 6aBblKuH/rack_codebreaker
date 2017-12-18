require 'erb'

class Racker
  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def response
    case @request.path
    when '/' then Rack::Response.new(render('index.html.erb'))
    when '/update_word'
      Rack::Response.new do |response|
        response.set_cookie('word', @request.params['word'])
        response.redirect('/')
      end
    when '/start'
      Rack::Response.new(render('difficulty.html.erb'))
    when '/difficulty'
      Rack::Response.new do |response|
        response.set_cookie('difficulty', @request.params['difficulty'])
        response.redirect('/start')
      end

    else Rack::Response.new('Not Found', 404)
    end
  end

  private
  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
