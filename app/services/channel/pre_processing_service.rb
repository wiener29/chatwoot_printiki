module Channel
  class PreProcessingService
    def initialize(conversation, params = {})
      @conversation = conversation
      @params = params
      @content = params[:content]
    end

    def perform
      # Skip if validation not required for this inbox/channel
      # For now, we enforce for VK only, or all channels without phone
      return true if @conversation.contact.phone_number.present?
      
      # If message content matches phone number pattern, update and proceed
      if extract_phone_number
        @conversation.contact.update(phone_number: @phone_number)
        send_confirmation
        return true
      end

      # Otherwise, prompt for phone number
      send_phone_prompt
      false
    end

    private

    def extract_phone_number
      # Simple regex for phone number extraction
      # Allow formats like +123..., 89..., 79...
      # Strip spaces, dashes, parens
      clean_content = @content.gsub(/\D/, '')
      
      # Basic check: length 10-15
      if clean_content.length >= 10 && clean_content.length <= 15
        @phone_number = "+#{clean_content}"
        return true
      end
      false
    end

    def send_phone_prompt
      Messages::MessageBuilder.new(
        nil,
        @conversation,
        {
          content: "Пожалуйста, введите ваш номер телефона для продолжения диалога.",
          message_type: :outgoing,
          private: false
        }
      ).perform
    end
    
    def send_confirmation
       Messages::MessageBuilder.new(
        nil,
        @conversation,
        {
          content: "Спасибо! Ваш номер сохранен. Чем я могу помочь?",
          message_type: :outgoing,
          private: false
        }
      ).perform
    end
  end
end
