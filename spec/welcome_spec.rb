# frozen_string_literal: true

RSpec.describe Welcome do
  subject { Welcome.new('test', '127.0.0.1') }

  context 'initialize instance' do
    it 'instance variables created' do
      expect(subject.instance_variable_get(:@name)).to eq('test')
      expect(subject.instance_variable_get(:@ip)).to eq('127.0.0.1')
    end
  end

  context '#log_in' do
    before { allow(subject).to receive(:old_user?).and_return(true) }

    it 'calls save_new_user method' do
      allow(subject).to receive(:old_user?)
      expect(subject).to receive(:save_new_user)
      subject.log_in
    end

    it 'calls save_new_user method' do
      expect(subject).to receive(:dataOrHash).with('games').and_call_original
      subject.log_in
    end

    it 'returns hash with user_id and game data' do
      data = subject.log_in
      expect(data).to be_kind_of Hash
      expect(data[:user_id]).to eq(subject.instance_variable_get(:@chyphered_name))
      expect(data[:game]).to eq(nil)
    end
  end

  context '#save_new_user' do
    it 'saves new user' do
      subject.instance_variable_set(:@cyphered_name, 'test')
      subject.instance_variable_set(:@name, 'test1')
      subject.instance_variable_set(:@users, {})
      expect(Storage).to receive(:save_record).with('users', { 'test' => 'test1' }.to_yaml)
      subject.send(:save_new_user)
    end
  end

  context '#to_cypher_user_name' do
    it 'calls the encryption method' do
      name = subject.instance_variable_get(:@name)
      ip = subject.instance_variable_get(:@ip)
      expect(Digest::MD5).to receive(:hexdigest).with("#{name}#{ip}").and_call_original
      subject.send(:to_cypher_user_name)
    end

    it 'returns instance variable chyphered_name' do
      expect(subject.send(:to_cypher_user_name)).to eq(:"9606f91d999d676d68343763e9ffc977")
    end
  end

  context '#old_user?' do
    it 'calls dataOrHash method' do
      expect(subject).to receive(:dataOrHash).with('users').and_call_original
      subject.send(:old_user?)
    end
  end

  context '#dataOrHash' do
    it 'calls method for loading data and returns empty hash' do
      expect(Storage).to receive(:load_file).with('test')
      expect(subject.send(:dataOrHash, 'test')).to eq({})
    end
  end
end
