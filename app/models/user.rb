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
    key_id = self.stripe_user_id.to_s
    Stripe::Balance.retrieve(stripe_account: key_id)
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


  def calculate_montly_stats
    stats_agg = {}

    Stripe::Charge.all.map do |c|
      c_year = Time.at(c.created).year
      c_month = Time.at(c.created).month

      if stats_agg[c_year]
        if stats_agg[c_year][c_month]
        else
          stats_agg[c_year][c_month] = []
        end
      else
        stats_agg[c_year] = {}
        stats_agg[c_year][c_month] = []
      end

      stats_agg[c_year][c_month].push [c.amount, c.amount_refunded]

    end

    return stats_agg
  end


  def self.calculate_averages(charges)
    previous_year = (DateTime.now - 1.year).year

    previous_values = charges[previous_year].values
    current_values = charges[previous_year + 1].values

    prev_income = previous_values.map { |x| [x.map { |x| x[0] }] }.flatten.sum
    curr_income = current_values.map { |x| [x.map { |x| x[0] }] }.flatten.sum

    yoy_value = (prev_income > curr_income) ? (prev_income/(curr_income-1)).abs : (curr_income/(prev_income-1)).abs

    return {
        avg_charges: (previous_values.map { |x| x.count }.sum / 12),
        avg_income: (prev_income / 12),
        avg_outcome: (previous_values.map { |x| [x.map { |x| x[1] }] }.flatten.sum / 12),
        yoy_value: yoy_value
    }
  end
end
