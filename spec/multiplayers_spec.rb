require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Role MultiPlayers' do

  context "A role can be played by many objects in the same context at the same time" do
    before(:all) do
      class TestingMultiplayersContext < DCI::Context
        role :role1 do
          def role1method1; :role1method1_executed end
          def role1self; self end
        end

        role :role2 do
          def role2method1; role1 end
          def role2self;   self   end

          private
          def private_role2method2; :private_rolemethod_return_value end
        end

        def get_role2_from_role1
         role1.send(:role2)
        end

        def multiplayer_dont_get_role
          [!role2.respond_to?(:role2method1), !role2.private_methods.map(&:to_s).include?('private_role2method2')].uniq == [true]
        end

        def multiplayer_players_get_their_role?
          role2players = role2[0..-1]
          [!role2players.empty?,
           (role2players.all? {|roleplayer| roleplayer.respond_to?(:role2method1)}),
           (role2players.all? {|roleplayer| roleplayer.role2method1 == role1}),
           (role2players.all? {|roleplayer| roleplayer.private_methods.map(&:to_s).include?('private_role2method2')}),

          ].uniq == [true]
        end

        def check_role2players_identity(*objs)
          objs.all? do |obj|
            index = objs.index(obj)
            [role2 != obj, role2[index] == obj, role2[index].role2self == obj,
             role2[index].send(:private_role2method2) == :private_rolemethod_return_value,
             obj.send(:private_role2method2)          == :private_rolemethod_return_value].uniq == [true]
          end
        end

        def roles2_external_interfaces_accessible?(*names)
          names.all? do |name|
            index = names.index(name)
            role2[index].name == name
          end
        end

        def roles2_have_context_private_access?
          role2[0..-1].all? do |roleplayer|
            [!roleplayer.respond_to?(:context), roleplayer.private_methods.map(&:to_s).include?('context'), roleplayer.send(:context) == self].uniq == [true]
          end
        end

        def roles2_have_settings_private_access?(settings_copy)
          role2[0..-1].all? do |roleplayer|
            [!roleplayer.respond_to?(:settings), roleplayer.private_methods.map(&:to_s).include?('settings'),
             roleplayer.send(:settings) == settings, roleplayer.send(:settings) == settings_copy,
             roleplayer.send(:settings, :setting2) == settings_copy[:setting2],
             roleplayer.send(:settings, :setting1, :setting3) == {:setting1 => settings_copy[:setting1], :setting3 => settings_copy[:setting3]}
            ].uniq == [true]
          end
        end

      end

      Player = Struct.new(:name)
      @player1, @player2, @player22 = Player.new('player1'), Player.new('player2'), Player.new('player22')
      @multiplayer = DCI::Multiplayer[@player2, @player22]
      #puts @multiplayer.instance_variable_get(:@players)
      @testing_roleplayers_context  = TestingMultiplayersContext.new(:role1    => @player1,
                                                                     :role2    => @multiplayer,
                                                                     :setting1 => :one,
                                                                     :setting2 => :two,
                                                                     :setting3 => :three)
    end

    it("For it to work, the developer has to give a rolekey the value of a DCI::Multiplayer instance when instantiating the context...") do
      @testing_roleplayers_context.get_role2_from_role1.should be(@multiplayer)
    end

    it("...so now, all the objects wrapped by the multiplayer instance play the role intended") do
      @testing_roleplayers_context.multiplayer_dont_get_role.should be_true
      @testing_roleplayers_context.multiplayer_players_get_their_role?.should be_true
    end

    it("...preserving their identity") do
      @testing_roleplayers_context.check_role2players_identity(@player2, @player22).should be_true
    end
    it("...and therefore, their state and behaviour are accessible inside the context.") do
      @testing_roleplayers_context.roles2_external_interfaces_accessible?(@player2.name, @player22.name).should be_true
    end

    it("They have private access to the context.") do
      @testing_roleplayers_context.roles2_have_context_private_access?.should be_true
    end

    it("And also private access to extra args received in the instantiation of its context.") do
      @testing_roleplayers_context.roles2_have_settings_private_access?({:setting1 => :one, :setting2 => :two, :setting3 => :three}).should be_true
    end

    it("But all these features, are only inside a context. Never out of it!") do
      @player2.should_not  respond_to(:role1method1)
      @player22.should_not respond_to(:role1method1)
      @player2.private_methods.map(&:to_s).should_not include(:private_role2method2)
      @player22.private_methods.map(&:to_s).should_not include(:private_role2method2)
      @player2.name.should eq('player2')
      @player22.name.should eq('player22')
      expect{@player2.send(:role1)}.to  raise_error
      expect{@player22.send(:role1)}.to raise_error
      @player2.send(:context).should  be_nil
      @player22.send(:context).should be_nil
      expect{@player2.send(:settings)}.to  raise_error
      expect{@player22.send(:settings)}.to raise_error
    end

  end

end
