Mongoid::Fields.option(:slug_id_strategy) do |model, field, value|
  field.options[:slug_id_strategy] = value
end
