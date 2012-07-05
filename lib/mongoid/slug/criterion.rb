module Mongoid::Slug::Criterion
  # Override Mongoid's finder to use slug or id
  def for_ids(*ids)
    return super unless @klass.ancestors.include?(Mongoid::Slug)

    # We definitely don't want to rescue at the same level we call super above -
    # that would risk applying our slug behavior to non-slug objects, in the case
    # where their id conversion fails and super raises BSON::InvalidObjectId
    begin
      # note that there is a small possibility that a client could create a slug that
      # resembles a BSON::ObjectId
      ids.flatten!
      Moped::BSON::ObjectId.from_string(ids.first) unless ids.first.is_a?(Moped::BSON::ObjectId)
      super # Fallback to original Mongoid::Criterion::Optional
    rescue Moped::BSON::InvalidObjectId
      # slug
      if ids.size > 1
        if @klass.slug_history_name
          any_of({ @klass.slug_name.to_sym.in => ids }, { @klass.slug_history_name.to_sym.in => ids })
        else
          where(@klass.slug_name.to_sym.in => ids)
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
Mongoid::Criteria.send :include, Mongoid::Slug::Criterion
