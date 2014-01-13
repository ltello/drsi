module DCI

  def self.Multiplayer(obj)
    obj.is_a?(::DCI::Multiplayer) ? obj : Multiplayer.new(obj)
  end


  class Multiplayer

    def self.[](*args)
      new(*args)
    end

    def each(&block)
      @players.each {|player| block.call(player)}
    end

    def initialize(*args)
      @players = args
    end

  end

end


