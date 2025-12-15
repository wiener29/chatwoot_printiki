# frozen_string_literal: true

class Channel::WhatsappGreenApi < ApplicationRecord
  include Channelable

  self.table_name = 'channel_whatsapp_green_api'
  EDITABLE_ATTRS = [:id_instance, :api_token_instance].freeze

  validates :id_instance, presence: true, uniqueness: true
  validates :api_token_instance, presence: true
  validates :account_id, presence: true

  def name
    'WhatsappGreenApi'
  end

  # Helper to construct API URL
  def api_url
    "https://api.green-api.com/waInstance#{id_instance}"
  end
end
