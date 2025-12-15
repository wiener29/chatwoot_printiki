# frozen_string_literal: true

class Channel::Max < ApplicationRecord
  include Channelable

  self.table_name = 'channel_max'
  EDITABLE_ATTRS = [:instance_id, :api_token].freeze

  validates :instance_id, presence: true, uniqueness: true
  validates :api_token, presence: true
  validates :account_id, presence: true

  def name
    'Max'
  end
end
