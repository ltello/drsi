require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DCI::Context do

  context "Definition:" do
    context "When Inheriting from DCI::Context..." do
      before(:all) do
        class TestingDefinitionContext < DCI::Context
          role :role_name do
            def role_name_method
            end
          end

          def interaction1
          end
        end
      end

      it("...a new dci context is ready to be used...") {TestingDefinitionContext.superclass.should be(DCI::Context)}
      it("...in which the developer can define roles...") do
        TestingDefinitionContext.private_methods.map(&:to_s).should include("role")
      end
      it("...but privately inside the subclass.") {TestingDefinitionContext.should_not respond_to(:role)}

      it("A role is defined calling the private macro #role with a role_key and a block defining the specific methods of the role.") do
        TestingDefinitionContext.roles.size.should be(1)
        TestingDefinitionContext.roles.keys.should include(:role_name)
      end

      it("The #roles public class_and_instance_method will return a hash with pairs (role_key => ContextSubclass::Rolekey)...") do
        TestingDefinitionContext.roles.should eq({:role_name => TestingDefinitionContext::RoleName})
        TestingDefinitionContext.new(:role_name => Object.new).send(:roles).should eq(:role_name => TestingDefinitionContext::RoleName)
      end
      it("... where every ContextSubclass::Rolekey is a new module created at load time,...") do
        TestingDefinitionContext.roles[:role_name].should be_a(Module)
        TestingDefinitionContext.roles[:role_name].should be(TestingDefinitionContext::RoleName)
      end
      it("... named after the associated role_key...") do
        TestingDefinitionContext.const_defined?(:RoleName).should be(true)
      end
      it("... and defined after the block given to the associated role in its definition.") do
        TestingDefinitionContext::RoleName.public_instance_methods.map(&:to_s).should include("role_name_method")
      end

      it("Inside the context subclass, the developer defines context methods (instance methods) that act as interactions.") do
        TestingDefinitionContext.public_instance_methods(false).map(&:to_s).should include('interaction1')
      end
    end
  end

  context "Use:" do
    context "To use a Context..." do
      before(:all) do
        class TestingUseContext < DCI::Context
          role :role1 do
            def role1_method
              :role1_method
            end
          end
          role :role2 do
          end

          def run
            role1.role1_method
          end

          def interaction2
            role1
          end

          def interaction3
            role1.object_id - role2.object_id
          end
        end
        @player1, @player2 = Object.new, Object.new
        @context_instance_1 = TestingUseContext.new(:role1 => @player1, :role2 => @player2)
        @context_instance_2 = TestingUseContext.new(:role1 => @player1, :role2 => @player2, :extra_arg => :extra)
      end

      it("...instanciate it from its correspondig DCI::Context subclass as usual...") do
        @context_instance_1.should be_a(TestingUseContext)
      end
      it("...providing pairs of type :rolekey1 => player1 as arguments...") do
        expect {TestingUseContext.new(@player1, @player2)}.to raise_error
      end
      it("...with ALL the role_keys in the subclass as keys...") do
        expect {TestingUseContext.new(:role1 => @player1)}.to raise_error(/missing roles(.+)role2/)
      end
      it("...and the objects to play those roles as values.") do
        @context_instance_1.interaction2
        [@player1, @player2].should include(@context_instance_1.send(:role1), @context_instance_1.send(:role2))
      end

      it("...You can also include other extra pairs as arguments...") do
        expect {TestingUseContext.new(:role1 => @player1, :role2 => @player2, :extra_arg => :extra)}.not_to raise_error
      end

      it("A shorter way to instantiate a context is through the class method []...") do
        expect {TestingUseContext[:role1 => @player1, :role2 => @player2, :extra_arg => :extra]}.not_to raise_error
      end
      it("...which is equivalent to create a new instance and call #run on it.") do
        TestingUseContext[:role1 => @player1, :role2 => @player2].should be(:role1_method)
      end


      it("Once instantiated...") {@context_instance_1.should be_a(TestingUseContext)}
      it("...you call an interaction (instance method) on it") do
        @context_instance_1.should respond_to(:interaction2)
      end
      it("...to start interaction among roleplayers inside the context.") do
        @context_instance_1.interaction3.should be_instance_of(Fixnum)
      end

    end
  end

end
