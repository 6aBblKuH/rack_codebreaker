# frozen_string_literal: true

RSpec.describe Storage do
  subject { Storage }
  before { stub_const('Storage::PATH', 'spec/tests_data/') }

  context '.file_path' do
    it 'returns path' do
      path = subject.file_path('test')
      expect(path).to eq("#{subject::PATH}test.yml")
      expect(path).to be_kind_of String
    end
  end

  context '.load_file' do
    it 'loads truly file data' do
      path = "#{subject::PATH}test.yml"
      data = 'test'
      File.new(path, 'w+') unless File.exist?(path)
      File.write(path, data.to_yaml)
      expect(subject.load_file('test')).to eq(data)
      File.delete(path)
    end
  end

  context '.save_record' do
    it 'saves data' do
      path = "#{subject::PATH}test_file.yml"
      subject.save_record('test_file', 'test'.to_yaml)
      expect(YAML.load_file(path)).to eq('test')
      expect(File.exist?(path)).to be_truthy
      File.delete(path)
    end
  end

  context '.save_statistic' do
    before { allow(Time).to receive(:now).and_return(0) }
    let(:data) { { user_id: { wins_count: 1, date: 0 } } }
    let(:path) { "#{subject::PATH}statistic.yml" }

    it 'calls truly methods' do
      expect(subject).to receive(:load_file).with('statistic').and_call_original
      expect(subject).to receive(:save_record).with('statistic', data.to_yaml)
      subject.send(:save_statistic, :user_id)
    end

    it 'saves data' do
      subject.send(:save_statistic, :user_id)
      expect(YAML.load_file(path)).to eq(data)
    end

    after { File.delete(path) if File.exist?(path) }
  end
end
