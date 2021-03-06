module ApplicationHelper

  # Lookup logged in user from session, if applicable.
  def current_user
    @_current_user ||= User.find_by_id( session[:user_id] )
  end

  # Simply checks if the @user instance variable
  # is the current user. Used to check if we're
  # looking our own profile page, basically.
  # See app/views/users/show.html.haml
  def is_myself?
    @user == current_user
  end

  def self.pretty_balance
    balance_object.available.map{|o| "#{o.amount} #{o.currency}"}.join(',')
  end

  def format_json(obj)
    "<strong>#{obj.count} of elements</strong><br /><br />".html_safe + " =>#{obj.inspect}" #TODO: IMPLEMENT ME :)
  end

  def pretty_month(num)
    Date::MONTHNAMES[num]
  end
end
