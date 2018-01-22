RSpec.describe Guess do
  subject { Guess.new('1111', Codebreaker::Game.new([1, 2, 3, 4], 10, [1])) }

  context 'inintializing' do
    it 'defines needed instance variables' do
      expect(subject.instance_variable_get(:@user_code)).to eq('1111')
      expect(subject.instance_variable_get(:@game)).to be_kind_of Codebreaker::Game
      expect(subject.instance_variable_get(:@path)).to be_kind_of String
    end
  end

  context '#handle_guess' do
    it 'calls method win?' do
      expect(subject).to receive(:win?)
      subject.send(:handle_guess)
    end

    it 'defines instance variable @current_guess' do
      subject.send(:handle_guess)
      current_guess = subject.instance_variable_get(:@current_guess)
      expect(current_guess).to be_kind_of Hash
      %i'user_code match'.each { |key| expect(current_guess.key?(key)).to be_truthy }
    end

    it 'returns path' do
      path = subject.send(:handle_guess)
      expect(path).to be_kind_of String
      expect(path[0]).to eq('/')
    end
  end

  context '#win?' do
    it 'calls needed method' do
      expect(subject.instance_variable_get(:@game)).to receive(:equal_codes?).with(subject.instance_variable_get(:@user_code))
      subject.send(:win?)
    end
  end
end
