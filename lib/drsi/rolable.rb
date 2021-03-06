require 'drsi/module'

# This module defines a mechanism to extend and 'unextend' modules in an object.
#
# The idea is to provide an object with a heap of extended modules:
#   the highest ones filled with the methods associated to the roles the object currently plays,
#   and the lowest ones, clean (no methods) when the object finishes playing roles.
# reusing the empty ones or adding and extending new ones when it is needed.
module Rolable

  # Make an object play (in the given 'a_context') the role defined as a module in 'role_mod':
  #  - Get or extend a new empty role module,
  #  - Copy role_mod instance_methods into it,
  #  - Inject __context and settings methods.
  def __play_role!(a_rolekey, role_mod, a_context)
    new_role = __next_role_for(role_mod)
    new_role.class_exec(a_context, a_rolekey) do |the_context, the_rolekey|
      private
      define_method(:__rolekey) {the_rolekey}
      define_method(:__context) {the_context}
      define_method(:settings) {|*keys| __context.send(:settings, *keys)}
    end
  end

  # Make an object stop playing the last role it plays, if any.
  def __unplay_last_role!
    if role = __last_role
      methods = role.public_instance_methods(false) + role.protected_instance_methods(false) + role.private_instance_methods(false)
      methods.each {|name| role.send(:remove_method, name)}
      @__last_role_index = __last_role_index - 1
    end
  end


  private

    def __roles
      @__roles ||= Array.new
    end

    def __last_role_index
      @__last_role_index ||= -1
    end

    def __last_role
      __roles[__last_role_index]
    end

    # Returns the highest role module free of methods. If none, creates a new empty module ready to be filled with
    # role instance methods.
    def __next_role_for(mod)
      @__last_role_index = __last_role_index + 1
      new_role = __last_role
      new_role ? new_role.__copy_instance_methods_from(mod) : __add_role_for(mod)
    end

    # Creates and extends a new module ready to be filled with role instance methods.
    def __add_role_for(mod)
      role = mod.dup
      extend(role)
      __roles << role
      role
    end

    # The context within this object is playing its last role. This method must be overidden in every __role definition module.
    def __context
      nil
    end

    # The rolekey this object is playing its last role. This method must be overidden in every __role definition module.
    def __rolekey
      nil
    end
end
