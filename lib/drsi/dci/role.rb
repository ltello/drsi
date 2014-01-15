module DCI
  module Role

    private

      def context
        raise 'This method must be redefined in every module extending DCI::Role'
      end

      # Defines a new private reader instance method for a context mate role, delegating it to the context object.
      def add_role_reader_for!(rolekey)
        return if private_method_defined?(rolekey)
        define_method(rolekey) {__context.send(rolekey)}
        private rolekey
      end

  end
end
