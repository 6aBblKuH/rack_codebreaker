RSpec.describe Helper do
  subject { Helper.new(Rack::Request.new) }

  context '.new_game_data' do
    it 'calls needed method' do
      %i(easy medium hard).each do |diff|
        expect(Codebreaker::Game).to receive(:generate_game_data).with(diff).and_call_original
        Helper.new_game_data(diff)
      end
    end

    it 'returns hash with right data' do
      %i(easy medium hard).each do |diff|
        data = Helper.new_game_data(diff)
        expect(data[:hints].size).to eq(Codebreaker::Game::DIFFICULTIES.dig(diff, :hints))
        expect(data[:attempts]).to eq(Codebreaker::Game::DIFFICULTIES.dig(diff, :attempts))
        expect(data[:secret_code]).to be_kind_of Array
        expect(data[:secret_code].size).to eq(4)
      end
    end
  end
end
