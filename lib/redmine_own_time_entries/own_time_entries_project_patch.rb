module OwnTimeEntriesProjectPatch

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      unloadable

      class << self
        alias_method_chain :allowed_to_condition, :own_time_entries
      end

    end
  end


  module ClassMethods
    # Returns a SQL conditions string used to find all projects for which +user+ has the given +permission+
    #
    # Valid options:
    # * :project => limit the condition to project
    # * :with_subprojects => limit the condition to project and its subprojects
    # * :member => limit the condition to the user projects
    def allowed_to_condition_with_own_time_entries(user, permission, options={})
      statement = allowed_to_condition_without_own_time_entries(user, permission, options)
      statement_by_role = {}
      if user.logged? and (permission == :view_time_entries)
        user.projects_by_role.each do |role, projects|
          if role.allowed_to?(:view_only_own_time_entries) && projects.any?
            statement_by_role[role] = "#{Project.table_name}.id IN (#{projects.collect(&:id).join(',')})"
          end
        end
      end

      if statement_by_role.empty?
        statement
      else
        statement.chomp("))") << " OR (#{statement_by_role.values.join(' OR ')})) AND #{TimeEntry.table_name}.user_id = #{user.id})"
      end
    end

  end

end
