# frozen_string_literal: true

# Warden hook to check expire_datetime on each request.
# If the user/admin's expire_datetime has passed during their session,
# they will be signed out on the next request.
Warden::Manager.after_set_user do |record, warden, options|
  scope = options[:scope]
  if record.respond_to?(:account_expired?) && record.account_expired?
    warden.logout(scope)
    throw :warden, scope: scope, message: :account_expired
  end
end
