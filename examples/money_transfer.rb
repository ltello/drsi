require 'drsi'


class CheckingAccount
  attr_reader   :account_id, :currency
  attr_accessor :balance

  def initialize(account_id, initial_balance)
    @account_id  = account_id
    b, @currency = initial_balance.split(' ')
    @balance     = b.to_i
  end
end

class Amount
  attr_reader :quantity, :currency

  def initialize(data)
    q, @currency = data.split(' ')
    @quantity    = q.to_i
  end

  def to_s
    "#{quantity}#{currency}"
  end
end


class MoneyTransferContext < DCI::Context

  # Roles Definitions

    role :source_account do
      def run_transfer
        self.balance -= amount.quantity
        puts "\t\tAccount(\##{account_id}) sent #{amount} to Account(\##{target_account.account_id})."
      end
    end

    role :target_account do
      def run_transfer
        self.balance += amount.quantity
        puts "\t\tAccount(\##{account_id}) received #{amount} from Account(\##{source_account.account_id})."
      end
    end

    role :amount


  # Interactions

    def run
      puts "\nMoney Transfer of #{amount} between Account(\##{source_account.account_id}) and Account(\##{target_account.account_id})"
      puts "\tBalances Before: #{balances}"
      source_account.run_transfer
      target_account.run_transfer
      puts "\tBalances After:  #{balances}"
    end


  private

    def accounts
      [source_account, target_account]
    end

    def balances
      accounts.map {|account| "#{account.balance}#{account.currency}"}.join(' - ')
    end
end

acc1   = CheckingAccount.new(1, '1000 €')
acc2   = CheckingAccount.new(2, '0 €')
amount = Amount.new('200 €')

5.times do
  MoneyTransferContext.new(:source_account => acc1,
                           :target_account => acc2,
                           :amount         => amount).run
end
