# frozen_string_literal: true

class Channel::Vk < ApplicationRecord
  include Channelable

  self.table_name = 'channel_vk'
  EDITABLE_ATTRS = [:group_id, :access_token, :confirmation_token, :secret_key].freeze

  validates :group_id, presence: true, uniqueness: true
  validates :access_token, presence: true
  validates :confirmation_token, presence: true
  validates :account_id, presence: true

  def name
    'Vk'
  end
end
