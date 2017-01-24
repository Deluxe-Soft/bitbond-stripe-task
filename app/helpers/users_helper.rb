module UsersHelper
  def self.pretty_balance(balance_object)
    balance_object.available.map{|o| "#{o.amount} #{o.currency}"}.join(',')
  end
end
