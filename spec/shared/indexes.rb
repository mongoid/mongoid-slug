shared_examples "has an index" do |key, options|
  it "has a #{[key, options].compact.join(', ')} index" do
    index_key, index_value = select_index(subject, key)

    # assert exact order of index keys
    index_key.keys.should   eq key.keys
    index_key.values.should eq key.values

    options.each_pair { |name, value|
      if Mongoid::Slug.mongoid3?
        index_value[name].should == value
      else
        index_value.options[name].should == value
      end
    } if options
  end
end

shared_examples "does not have an index" do |key|
  it "does not have the #{key} index" do
    index_key, index_value = select_index(subject, key)
    index_key.should   be_nil
    index_value.should be_nil
  end
end

def select_index(subject, key)
  if Mongoid::Slug.mongoid3?
    subject.index_options.select{|k, v| k == key}.first
  else
    subject.index_specifications.select{|spec| spec.key == key}.first
  end
end
