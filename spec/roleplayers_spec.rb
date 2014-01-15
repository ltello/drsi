require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'RolePlayers' do

  context "Are Ruby objects inside a context instance..." do
    before(:all) do
      class TestingRoleplayersContext < DCI::Context
        role :role1 do
          def role1method1; :role1method1_executed end
          def role1self; self end
        end

        role :role2 do
          def role2method1; role1 end
          def role2self;   self  end

          private
          def private_role2method2; :private_rolemethod_return_value end
        end

        def check_role_interaccess
          [role2.role2method1 == role1, !role2.respond_to?(:role1)].uniq == [true]
        end

        def check_role1_identity(obj)
          [role1 == obj, role1.role1self == obj, role1.respond_to?(:role1method1), obj.respond_to?(:role1method1),
           role1.role1method1 == :role1method1_executed, obj.role1method1 == :role1method1_executed].uniq == [true]
        end

        def check_role2_identity(obj)
          [role2 == obj, role2.role2self == obj, role2.respond_to?(:role2method1), obj.respond_to?(:role2method1),
           role2.send(:private_role2method2) == :private_rolemethod_return_value,
           obj.send(:private_role2method2)   == :private_rolemethod_return_value,
           role2.role2method1 == role1, obj.role2method1 == role1].uniq == [true]
        end

        def access_role1_external_interface
          role1.name
        end

        def check_role1_private_context_access
          [!role1.respond_to?(:__context), role1.private_methods.map(&:to_s).include?('__context'), role1.send(:__context) == self,
           !role1.respond_to?(:__rolekey), role1.private_methods.map(&:to_s).include?('__rolekey'), role1.send(:__rolekey) == :role1].uniq == [true]
        end

        def check_role1_settings_access
         [!role1.respond_to?(:settings), role1.private_methods.map(&:to_s).include?('settings'),
          role1.send(:settings) == settings].uniq == [true]
        end
      end

      Player = Struct.new(:name)
      @player1, @player2 = Player.new('player1'), Player.new('player2')
      @testing_roleplayers_context = TestingRoleplayersContext.new(:role1    => @player1,
                                                                   :role2    => @player2,
                                                                   :setting1 => :one,
                                                                   :setting2 => :two,
                                                                   :setting3 => :three)
    end

    it("...that adquire the public instance methods defined in their role...") do
      @testing_roleplayers_context.check_role1_identity(@player1).should be_true
    end
    it("...as well as the private ones.") do
      @testing_roleplayers_context.check_role2_identity(@player2).should be_true
    end

    it("They still preserve their identity") do
      @testing_roleplayers_context.check_role1_identity(@player1).should be_true
    end
    it("...and therefore, their state and behaviour are accessible inside the context.") do
      @testing_roleplayers_context.access_role1_external_interface.should eq('player1')
    end

    it("Inside the context, roleplayers have private access to other roleplayers through methods named after their keys.") do
      @testing_roleplayers_context.check_role_interaccess.should be_true
    end
    it("...as well as private access to the context.") do
      @testing_roleplayers_context.check_role1_private_context_access.should be_true
    end

    it("They also have private access to extra args received in the instantiation of its context...") do
      @testing_roleplayers_context.check_role1_settings_access.should be_true
    end
    it("...calling #settings that returns a hash with all the extra args...") do
      @testing_roleplayers_context.send(:settings).should eq({:setting1 => :one, :setting2 => :two, :setting3 => :three})
    end
    it("...or #settings(key) that returns the value of the given extra arg...") do
      @testing_roleplayers_context.send(:settings, :setting2).should be(:two)
    end
    it("...or #settings(key1, key2, ...) that returns a hash with the given extra args.") do
      @testing_roleplayers_context.send(:settings, :setting1, :setting3).should eq({:setting1 => :one, :setting3 => :three})
    end

    it("But all these features, are only inside a context. Never out of it!") do
      @player1.should_not respond_to(:role1method1)
      @player2.private_methods.map(&:to_s).should_not include(:private_role2method2)
      @player1.name.should eq('player1')
      @player2.send(:__context).should be_nil
      expect {@player2.send(:settings)}.to raise_error
      expect {@player2.send(:role1)}.to raise_error
    end

  end

end
