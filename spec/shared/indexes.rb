shared_examples 'has an index' do |key, options|
  it "has a #{key} index" do
    index = if Mongoid::Compatibility::Version.mongoid3?
              subject.index_options[key]
            else
              subject.index_specifications.detect { |spec| spec.key == key }
            end
    expect(index).not_to be_nil
    options.each_pair do |name, value|
      if Mongoid::Compatibility::Version.mongoid3?
        expect(index[name]).to eq(value)
      else
        expect(index.options[name]).to eq(value)
      end
    end if options
  end
end

shared_examples 'does not have an index' do |key, _option|
  it "does not have the #{key} index" do
    if Mongoid::Compatibility::Version.mongoid3?
      expect(subject.index_options[key]).to be_nil
    else
      expect(subject.index_specifications.detect { |spec| spec.key == key }).to be_nil
    end
  end
end
