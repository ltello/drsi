module DCI

  # The intend of this method is to create something similar to Array():
  # When called with a Multiplayer object, returns the object unmodified.
  # Otherwise, retuns a new Multiplayer object wrapping the given argument.
  def self.Multiplayer(obj)
    obj.is_a?(::DCI::Multiplayer) ? obj : Multiplayer.new(obj)
  end


  # This simple class lets collect together a list of any type of objects.
  # If you pass a multiplayer collection instance as the role player when instantiating a context,
  # every object of the collection get the role instead of the multiplayer instance itself.
  # So this is the way for different objects to play the similar roles at the same time in a DCI Context.
  class Multiplayer

    # Syntax sugar to easy the creation of Multiplayer instances.
    def self.[](*args)
      new(*args)
    end

    def each(&block)
      @players.each {|player| block.call(player)}
    end

    # Give access to the players of this instance in a way similar to an array:
    # multiplayer[1], multiplayer[1..5], multiplayer[-2], ...
    def [](index)
      @players[index]
    end

    def initialize(*args)
      @players = args
    end

  end

end


