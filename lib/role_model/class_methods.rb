module RoleModel
  module ClassMethods
    def inherited(subclass) # :nodoc:
      ::RoleModel::INHERITABLE_CLASS_ATTRIBUTES.each do |attribute|
        instance_var = "@#{attribute}"
        subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
      end
      super
    end

    # set the bitmask attribute role assignments will be stored in
    def roles_attribute(name)
      self.roles_attribute = name
    end

    # alternative method signature: set the bitmask attribute role assignments will be stored in
    def roles_attribute=(name)
      self.roles_attribute_name = name.to_sym
    end

    # :call-seq:
    #   roles(:role_1, ..., :role_n)
    #   roles('role_1', ..., 'role_n')
    #   roles([:role_1, ..., :role_n])
    #   roles(['role_1', ..., 'role_n'])
    #
    # declare valid roles
    def roles(*roles)
      self.valid_roles = Array[*roles].flatten.map { |r| r.to_sym }
    end

    def mask_for(*roles)
      (Array[*roles].map {|r|
        r.respond_to?(:each) ? r.to_a : r
      }.flatten.map { |r|
        r.to_sym
      } & valid_roles).map { |r|
        2**valid_roles.index(r)
      }.inject { |sum, bitvalue|
        sum + bitvalue
      } || 0
    end

    # All masks we can get with role
    # Can be usefull when we want to retrieve a user with a specific role from database
    # Ex: User.where(roles_mask => User.possible_masks_for(:admin))
    # => SELECT `users`.* FROM `users` WHERE `users`.`roles_mask` IN (1, 3)
    def possible_masks_for(role)
      role_combinations_for(role).collect do |combination|
        self.mask_for combination
      end
    end

    def role_combinations
      1.upto(self.valid_roles.size).collect do |number_of_elements|
        self.valid_roles.combination(number_of_elements).to_a
      end.flatten(1)
    end

    def role_combinations_for(role)
      role_combinations.select { |combination| combination.include?(role)}
    end
  end
end
