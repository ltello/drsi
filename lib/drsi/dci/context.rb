require 'drsi/dci/role'

module DCI
  class Context

    class << self

      # Every subclass of Context has is own class and instance method roles defined.
      # The instance method delegates value to the class.
      def inherited(subklass)
        subklass.class_eval do
          @roles ||= {}
          def self.roles; @roles end
          def roles; self.class.roles end
          private :roles
          assign_unplay_roles_within_klass_instance_methods!(subklass)
        end
      end

      # A short way for ContextSubclass.new(players_and_extra_args).run(extra_args)
      def [](*args)
        new(*args).run
      end


      private

        # The macro role is defined to allow a subclass of Context to define roles in its definition body.
        # Every new role is added to the hash of roles in that Context subclass.
        # A reader to access the object playing the new role is also defined and available in every instance of the context subclass.
        # Also, readers to allow each other role access are defined.
        def role(rolekey, &block)
          raise "role name must be a symbol" unless rolekey.is_a?(Symbol)
          create_role_from(rolekey, &block)
          define_reader_for_role(rolekey)
          define_mate_roleplayers_readers_after_newrole(rolekey)
        end

        # Adds a new entry to the roles accumulator hash.
        def create_role_from(key, &block)
          roles.merge!(key => create_role_subclass_from(key, &block))
        end

        # Defines and return a new subclass of DCI::Role named after the given rolekey and with body the given block.
        def create_role_subclass_from(rolekey, &block)
          new_klass_name = rolekey.to_s.split(/\_+/).map(&:capitalize).join('')
          const_set(new_klass_name, Class.new(::DCI::Role, &block))
        end

        # Defines a private reader to allow a context instance access to the roleplayer object associated to the given rolekey.
        def define_reader_for_role(rolekey)
          private
          attr_reader rolekey
        end

        # After a new role is defined, you've got to create a reader method for this new role in the rest of context
        # roles, and viceverse: create a reader method in the new role klass for each of the other roles in the context.
        # This method does exactly this.
        def define_mate_roleplayers_readers_after_newrole(new_rolekey)
          new_roleklass = roles[new_rolekey]
          mate_roles    = mate_roles_of(new_rolekey)
          mate_roles.each do |mate_rolekey, mate_roleklass|
            mate_roleklass.send(:add_role_reader_for!, new_rolekey)
            new_roleklass.send(:add_role_reader_for!, mate_rolekey)
          end
        end

        # For a give role key, returns a hash with the rest of the roles (pair :rolekey => roleklass) in the context it belongs to.
        def mate_roles_of(rolekey)
          roles.dup.tap do |roles|
            roles.delete(rolekey)
          end
        end

        # Wraps every existing public/protected instance_method of klass (not superclasses methods) to assign roles to
        # player objects before the execution and to un-assign roles from player objects at the end of execution just
        # before returning control.
        # Also inject code to magically do the same to every new method defined in klass.
        def assign_unplay_roles_within_klass_instance_methods!(klass)
          klass.instance_methods(false).each do |existing_methodname|
            assign_unplay_roles_within_klass_instance_method!(klass, existing_methodname)
          end
          def klass.method_added(methodname)
            if not @context_internals and public_method_defined?(methodname)
              @context_internals = true
              assign_unplay_roles_within_klass_instance_method!(self, methodname)
              @context_internals = false
            end
          end
        end

        # Wraps the given klass's methodname to assign/un-assign roles to player objects before and after actual method
        # execution.
        def assign_unplay_roles_within_klass_instance_method!(klass, methodname)
          klass.class_eval do
            method_object = instance_method(methodname)
            define_method(methodname) do |*args, &block|
              players_play_role!
              method_object.bind(self).call(*args, &block).tap {players_unplay_role!}
            end
          end
        end

    end


    # Instances of a defined subclass of Context are initialized checking first that all subclass defined roles
    # are provided in the creation invocation raising an error if any of them is missing.
    # Once the previous check is met, every object playing in the context instance is associated to the stated role.
    # Non players args are associated to instance_variables and readers defined.
    def initialize(args={})
      check_all_roles_provided_in!(args)
      players, noplayers = args.partition {|key, *| roles.has_key?(key)}.map {|group| Hash[*group.flatten]}
      @_players = players
      @settings = noplayers
    end


    private

      # Private access to the extra args received in the instantiation.
      # Returns a hash (copy of the instantiation extra args) with only the args included in 'keys' or all of them
      # when called with no args.
      def settings(*keys)
        return @settings.dup if keys.empty?
        entries = @settings.reject {|k, v| !keys.include?(k)}
        keys.size == 1 ? entries.values.first : entries
      end

      # Checks there is a player for each role.
      # Raises and error message in case of missing roles.
      def check_all_roles_provided_in!(players={})
        missing_rolekeys = missing_roles(players)
        raise "missing roles #{missing_rolekeys}" unless missing_rolekeys.empty?
      end

      # The list of roles with no player provided
      def missing_roles(players={})
        (roles.keys - players.keys)
      end

      # Associates every role to the intended player.
      def players_play_role!
        roles.keys.each do |rolekey|
          assign_role_to_player!(rolekey, @_players[rolekey])
        end
      end

      # Associates a role to an intended player:
      #   - The player object is 'extended' with the methods of the role to play.
      #   - The player get access to the context it is playing.
      #   - The player get access to the rest of players in its context through instance methods named after their role keys.
      #   - This context instance get access to this new role player through an instance method named after the role key.
      def assign_role_to_player!(rolekey, player)
        role_klass = roles[rolekey]
        player.__play_role!(role_klass, self)
        instance_variable_set(:"@#{rolekey}", player)
      end

      # Disassociates every role from the playing object.
      def players_unplay_role!
        roles.keys.each do |rolekey|
          @_players[rolekey].__unplay_last_role!
          # 'instance_variable_set(:"@#{rolekey}", nil)
        end
      end

  end
end
