require 'net/http'
require 'uri'

module Vk
  class SendOnVkService < Base::SendOnChannelService
    VK_API_URL = 'https://api.vk.com/method/messages.send'
    API_VERSION = '5.131'

    def perform
      return unless @message.channel.is_a?(Channel::Vk)

      send_message
    end

    private

    def send_message
      uri = URI(VK_API_URL)
      
      peer_id = @message.conversation.contact.source_id # Assuming source_id stores VK User ID

      params = {
        access_token: @message.channel.access_token,
        v: API_VERSION,
        user_id: peer_id, # user_id or peer_id
        message: @message.content,
        random_id: @message.id # Unique ID to prevent duplication
      }

      response = Net::HTTP.post_form(uri, params)
      json = JSON.parse(response.body)

      if json['error']
        Rails.logger.error "VK API Error: #{json['error']}"
        raise StandardError, "VK Failed: #{json['error']['error_msg']}"
      end
    end
  end
end
