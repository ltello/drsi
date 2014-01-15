class Module

  # Define instance methods delegating execution to the corresponding ones in 'mod'.
  def __copy_instance_methods_from(mod)
    [:public_instance_methods, :protected_instance_methods, :private_instance_methods].each do |methods_type|
      methods = mod.send(methods_type, false).map {|methodname| mod.instance_method(methodname)}
      type    = methods_type.to_s.split('_').first.to_sym
      __add_instance_methods(methods, type)
    end
  end


  private

    # Define instance methods binding to self the unbound ones received in 'methods'.
    # Also, set their visibility from 'type' (:public, :protected, :private).
    def __add_instance_methods(methods, type)
      module_exec(methods, type) do |methods, type|
        methods.each {|method| define_method(method.name, method)}
        send(type, *methods.map(&:name))
      end
    end

end
