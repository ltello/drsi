# drsi

**_Trygve Reenskaug_**, the parent of MVC, proposes an evolution to traditional OO paradigm: [The DCI Architecture: A New Vision of Object-Oriented Programming](http://www.artima.com/articles/dci_vision.html "The DCI Architecture: A New Vision of Object-Oriented Programming").

This gem makes Data-Context-Interaction paradigm ready to be used in your Ruby application. See also [Data Context Interaction: The Evolution of the Object Oriented Paradigm](http://rubysource.com/dci-the-evolution-of-the-object-oriented-paradigm/ "Data Context Interaction: The Evolution of the Object Oriented Paradigm").

## Installation

Install as usual, either with rubygems

    gem install drsi

or including it in your Gemfile and running bundle install:

    # Gemfile
    gem "drsi"

    $ bundle install

_**Note**: only **ruby 2.1+** compatible._


## Usage

dci-ruby gives you the class DCI::Context to inherit from to create your own contexts:

    class MoneyTransfer < DCI::Context

      # Roles

      role :source_account do
        def transfer(amount)
          self.balance -= amount
          target_account.get_transfer(amount)
        end
      end

      role :target_account do
        def get_transfer(amount)
          self.balance += amount
        end
      end


      # Interactions

      def run(amount = settings(:amount))
        source_account.transfer(amount)
      end
    end

Every context defines some roles to be played by external objects (players) and their interactions. This way
you have all the agents and operations in a use case wrapped in just one entity instead of spread out throughout the
application code.

Use the defined contexts, instantiating them, wherever you need in your code:

    MoneyTransfer.new(:source_account => Account.new(1),
                      :target_account => Account.new(2)).run(100)

or the short preferred way:

    MoneyTransfer[:source_account => Account.new(1),
                  :target_account => Account.new(2),
                  :amount         => 100]

Inside a context instance, every player object incorporates the behaviour (methods) defined by its role while keeping its own.

The Account instances above are players. They are accesible inside #run through #source_account and #target_account private methods.
Also, every role player has private access to the rest of role players in the context.

Unlike the Presenter approach in dci-ruby (where the object to play a role and the one inside the context playing it are associated but different), this extending/unextending approach preserves unique identity of objects playing roles.

When instanciating a Context, the extra no-role pairs given as arguments are read-only attributes accessible via #settings:

    MoneyTransfer[:source_account => Account.new(1),
                  :target_account => Account.new(2),
                  :amount => 500]

here, :amount is not a player (has no associated role) but is still privately accessible both in the interactions and the roles
via #settings(:amount).


See the [examples](https://github.com/ltello/drsi/tree/master/examples) folder for examples of use and the [drsi-DCI-Sample](https://github.com/ltello/drsi-DCI-Sample) repository for a sample Rails application using DCI through this gem.

Notice how your models and controllers are not overloaded anymore. They are thinner and simpler.
Also note how now most of the functionality of the system is isolated, totally dry-ied and easily maintainable in the different context classes.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Copyright

Copyright (c) 2012, 2013 Lorenzo Tello. See LICENSE.txt for further details.
