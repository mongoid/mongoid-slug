module Mongoid::Criterion::Optional
  # Override Mongoid's finder to use slug or id
  alias :for_ids! :for_ids
  def for_ids(*ids)
    ids.flatten!
    begin
      BSON::ObjectId.from_string(ids.first) unless ids.first.is_a?(BSON::ObjectId)
      # id
      if ids.size > 1
        any_in(:_id => ids)
      else
        where(:_id => ids.first)
      end
    rescue BSON::InvalidObjectId
      # slug
      if ids.size > 1
        if @klass.slug_history_name
          any_in({ @klass.slug_name => ids }, { @klass.slug_history_name => ids })
        else
          any_of({ @klass.slug_name => ids }, { @klass.slug_history_name => ids })
        end
      else
        if @klass.slug_history_name
          any_of({@klass.slug_name => ids.first}, {@klass.slug_history_name => ids.first})
        else
          where(@klass.slug_name => ids.first)
        end
      end
    end
  end
end

puts "LOADED"
