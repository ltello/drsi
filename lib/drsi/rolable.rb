require 'drsi/module'

# This module defines a mechanism to extend and 'unextend' modules in an object.
#
# The idea is to provide an object with a heap of extended modules:
#   the highest ones filled with the methods associated to the roles the object currently plays,
#   and the lowest ones, clean (no methods) when the object finishes playing roles.
# reusing the empty ones or adding and extending new ones when it is needed.
module Rolable

  # Make an object play the role defined as a module in 'mod'
  def __play_role!(role_klass, context)
    new_role = __next_empty_role
    new_role.__copy_instance_methods_from(role_klass)
    new_role.send(:define_method, :context) {context}
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
    def __next_empty_role
      @__last_role_index = __last_role_index + 1
      __add_empty_role! unless __last_role
      __last_role
    end

    # Creates and extends a new module ready to be filled with role instance methods.
    def __add_empty_role!
      role = Module.new
      extend(role)
      __roles << role
    end

    # The context a role is played within. This method must be overidden in every __role definition module.
    def context
      nil
    end

    # The role definition code also have private access to the extra args given in the context instantiation.
    def settings(*keys)
      context.send(:settings, *keys) if context
    end
end
