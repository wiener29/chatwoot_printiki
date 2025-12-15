module Webhooks
  class WhatsappGreenApiController < BaseController
    def process_payload
      @channel = Channel::WhatsappGreenApi.find_by(id_instance: params[:id_instance])
      return head :not_found unless @channel

      # GreenAPI payload structure:
      # { typeWebhook: 'incomingMessageReceived', senderData: { chatId: '...', senderName: '...' }, messageData: { textMessageData: { textMessage: '...' } } }
      
      payload = params
      type = payload[:typeWebhook]

      if type == 'incomingMessageReceived'
        handle_incoming_message(payload)
      end

      head :ok
    end

    private

    def handle_incoming_message(payload)
      sender_data = payload[:senderData]
      message_data = payload[:messageData]
      
      phone_number = sender_data[:chatId].gsub('@c.us', '')
      content = message_data.dig(:textMessageData, :textMessage)

      return if content.blank?

      contact = @channel.inbox.contacts.where(phone_number: "+#{phone_number}").first_or_create!(name: sender_data[:senderName] || phone_number)
      conversation = @channel.inbox.conversations.find_or_create_by(contact_id: contact.id)

      Messages::MessageBuilder.new(
        nil,
        conversation,
        {
          content: content,
          message_type: :incoming,
          sender: contact
        }
      ).perform
    end
  end
end
