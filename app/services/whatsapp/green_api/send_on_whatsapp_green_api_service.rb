require 'net/http'
require 'json'

module Whatsapp
  module GreenApi
    class SendOnWhatsappGreenApiService < Base::SendOnChannelService
      def perform
        return unless @message.channel.is_a?(Channel::WhatsappGreenApi)

        # Logic to send message to GreenAPI
        send_message
      end

      private

      def send_message
        uri = URI("#{@message.channel.api_url}/SendMessage/#{@message.channel.api_token_instance}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        
        phone_number = @message.conversation.contact.phone_number.gsub('+', '')
        chat_id = "#{phone_number}@c.us"

        payload = {
          chatId: chat_id,
          message: @message.content
        }

        request.body = payload.to_json
        response = http.request(request)
        
        if response.code != '200'
          Rails.logger.error "GreenAPI Error: #{response.body}"
          raise StandardError, "GreenAPI Failed: #{response.body}"
        end
      end
    end
  end
end
