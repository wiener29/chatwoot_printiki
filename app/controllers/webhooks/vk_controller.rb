module Webhooks
  class VkController < BaseController
    def process_payload
      @channel = Channel::Vk.find_by(group_id: params[:group_id])
      # VK sends confirmation request before channel is fully configured/verified, 
      # but we need the channel record to get the confirmation token.
      # Users must create the channel in Chatwoot first.
      return head :not_found unless @channel

      type = params[:type]

      if type == 'confirmation'
        render plain: @channel.confirmation_token
        return
      end

      if type == 'message_new'
        handle_incoming_message(params[:object][:message])
      end

      render plain: 'ok'
    end

    private

    def handle_incoming_message(message_data)
      user_id = message_data[:from_id]
      content = message_data[:text]

      return if content.blank?

      contact = @channel.inbox.contacts.where(source_id: user_id.to_s).first_or_create!(name: "VK User #{user_id}")
      conversation = @channel.inbox.conversations.find_or_create_by(contact_id: contact.id)

      should_proceed = Channel::PreProcessingService.new(conversation, { content: content }).perform
      return unless should_proceed

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
