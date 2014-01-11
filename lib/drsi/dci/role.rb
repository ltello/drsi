module DCI
  class Role

    class << self

      # Make this class abstract: will not allow create instances.
      def new(*args, &block)
        raise 'This class is meant to be abstract and not instantiable' if self == DCI::Role
        super
      end


      private

        # Defines a new private reader instance method for a context mate role, delegating it to the context object.
        def add_role_reader_for!(rolekey)
          return if private_method_defined?(rolekey)
          private
          define_method(rolekey) {context.send(rolekey)}
        end

    end

  end
end
