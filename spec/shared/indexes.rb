shared_examples "has an index" do |key, options|
  it "has a #{key} index" do
    index = if Mongoid::Slug.mongoid3?
      subject.index_options[key]
    else
      subject.index_specifications.detect { |spec| spec.key == key }
    end
    index.should_not be_nil
    options.each_pair { |name, value|
      if Mongoid::Slug.mongoid3?
        index[name].should == value
      else
        index.options[name].should == value
      end
    } if options
  end
end

shared_examples "does not have an index" do |key, option|
  it "does not have the #{key} index" do
    if Mongoid::Slug.mongoid3?
      subject.index_options[key].should be_nil
    else
      subject.index_specifications.detect { |spec| spec.key == key }.should be_nil
    end
  end
end
