require 'rack/test'

RSpec.describe Racker do
  include Rack::Test::Methods
  let(:env) { { 'HTTP_COOKIE' => 'user_id=%22b7db27c69a9c79df1b94d992b8665c0c%22; game=%7B%22attempts%22%3A30%2C%22hints%22%3A%5B1%2C4%2C5%5D%2C%22secret_code%22%3A%5B1%2C4%2C6%2C5%5D%7D' } }

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  context '#statuses_return' do
    %w(/ /game /win /lose /statistic).each do |path|
      it "#{path} responds ok? when had cookies" do
        get path, {}, env
        expect(last_response.status).to eql(200)
      end
    end

    it 'not found works' do
      get '/unknown'
      expect(last_response.status).to eql(404)
    end
  end

  context 'successful redirects' do
    it 'when log in' do
      post '/start', name: 'test'
      expect(last_response.redirect?).to be_truthy
    end

    it 'when starting new game' do
      post '/guess', { difficulty: '1234' }, env
      expect(last_response.redirect?).to be_truthy
    end

    it 'taking a hint' do
      get '/hint', {}, env
      expect(last_response.redirect?).to be_truthy
    end
  end
end
