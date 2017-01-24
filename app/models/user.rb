class User < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  serialize :stripe_account_status, JSON
  has_secure_password

  # General 'has a Stripe account' check
  def connected?; !stripe_user_id.nil?; end

  # Stripe account type checks
  def managed?; stripe_account_type == 'managed'; end
  def standalone?; stripe_account_type == 'standalone'; end
  def oauth?; stripe_account_type == 'oauth'; end

  def manager
    case stripe_account_type
    when 'managed' then StripeManaged.new(self)
    when 'standalone' then StripeStandalone.new(self)
    when 'oauth' then StripeOauth.new(self)
    end
  end

  def can_accept_charges?
    return true if oauth?
    return true if managed? && stripe_account_status['charges_enabled']
    return true if standalone? && stripe_account_status['charges_enabled']
    return false
  end

  def get_current_balance
    KEY_ID = self.stripe_user_id.to_s
    Stripe::Balance.retrieve(stripe_account: KEY_ID)
  end

  def self.get_all_sources_from_customer(customer)
    Stripe::Customer.retrieve(customer.id).sources.all(:object => "bank_account")
  end

  def self.stats_object_from_date(starting_date)
    {
        charges:          Stripe::Charge.list(created: {gte: starting_date}),
        refunds:          Stripe::Refund.list(created: {gte: starting_date}),
        disputes:         Stripe::Dispute.list(created: {gte: starting_date}),
        transfers:        Stripe::Transfer.list(created: {gte: starting_date}),
        customers:        Stripe::Customer.list,
        orders:           Stripe::Order.list(created: {gte: starting_date}),
        returns:          Stripe::OrderReturn.list(created: {gte: starting_date}),
        subscriptions:    Stripe::Subscription.list(created: {gte: starting_date})
    }
  end
end
