# frozen_string_literal: true

module BillingHelper
  # Overriding default_plan? to always return false.
  # This forces the system to use Account.usage_limits (derived from ChatwootApp.max_limit = 100_000)
  # effectively unlocking unlimited agents and inboxes.
  def default_plan?(_account)
    false
  end

  # Helper to identify if the account is on a paid plan (always true for Enterprise bypass)
  def subscribed?(_account)
    true
  end
end
