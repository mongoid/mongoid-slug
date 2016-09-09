shared_context 'with an index' do |key|
  if Mongoid::Compatibility::Version.mongoid3?
    let(:index) { subject.index_options[key] }
    let(:index_keys) { key }
    let(:index_options) { index }
  else
    let(:index) { subject.index_specifications.detect { |spec| spec.key == key } }
    let(:index_keys) { index.key }
    let(:index_options) { index.options }
  end
end

shared_examples 'has an index' do |key, options|
  include_context 'with an index', key

  it "has a #{[key, options].compact.join(', ')} index" do
    expect(index).not_to be_nil
  end

  it 'has the correct order of keys' do
    expect(index_keys.keys).to eq key.keys
  end

  it 'has the correct order of key values' do
    expect(index_keys.values).to eq key.values
  end

  it 'matches option values' do
    options.each_pair do |name, value|
      expect(index_options[name]).to eq(value)
    end
  end
end

shared_examples 'does not have an index' do |key|
  include_context 'with an index', key

  it "does not have the #{key} index" do
    expect(index).to be nil
  end
end
