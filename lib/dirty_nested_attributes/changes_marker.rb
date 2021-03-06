module DirtyNestedAttributes
  # Marks association record changes with ActiveRecord::Dirty behavior
  module ChangesMarker
    include ChangedAssociations

    # catch assignment for collection association and mark changes
    def assign_nested_attributes_for_collection_association(*args)
      super
      mark_associations_changes
    end

    # catch assignment for one to one association and mark changes
    def assign_nested_attributes_for_one_to_one_association(*args)
      super
      mark_associations_changes
    end

    private

    def mark_associations_changes
      self.class.reflect_on_all_autosave_associations.each do |reflection|
        association = association(reflection.name)
        if reflection.collection?
          mark_associations_changes_for_collection_association(association)
        else
          mark_associations_changes_for_single_association(association)
        end
      end
    end

    def mark_associations_changes_for_collection_association(association)
      records_that_will_change = association.target.select { |r| record_new_or_changed_or_marked_for_destruction?(r) }
      return if records_that_will_change.size == 0
      @changed_attributes[association.reflection.name] = records_that_will_change
    end

    def mark_associations_changes_for_single_association(association)
      return if association.target.blank? || !record_new_or_changed_or_marked_for_destruction?(association.target)
      @changed_attributes[association.reflection.name] = association.target
    end

    def record_new_or_changed_or_marked_for_destruction?(record)
      record.new_record? || record.changed? || record.marked_for_destruction?
    end
  end
end
