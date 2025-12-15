module AgentBots
  class AiResponseJob < ApplicationJob
    queue_as :low_priority

    def perform(conversation_id)
      conversation = Conversation.find(conversation_id)
      return unless conversation.inbox.ai_agent_enabled?
      
      # Safety check: ensure last message is from user (prevent loops)
      last_message = conversation.messages.last
      return if last_message.message_type != 'incoming'

      # Build History
      history = build_history(conversation)
      
      # Enhance System Prompt with Context if needed (e.g. from attributes)
      
      # Call Gemini
      config = {
        model: conversation.inbox.try(:ai_agent_model),
        system_instruction: conversation.inbox.try(:ai_agent_prompt)
      }
      ai_service = Ai::GeminiService.new(history, config)
      response_text = ai_service.generate_response

      if response_text.include?("[ESCALATE]")
        # Handle Escalation
        handle_escalation(conversation, response_text)
      else
        # Send Reply
        Messages::MessageBuilder.new(
          nil, # No specific user (bot)
          conversation,
          {
            content: response_text,
            message_type: :outgoing,
            private: false
          }
        ).perform
      end
    end

    private

    def build_history(conversation)
      # Fetch last 10 messages
      messages = conversation.messages.reorder(created_at: :desc).limit(10).reverse
      messages.map do |msg|
        role = msg.message_type == 'incoming' ? 'user' : 'assistant'
        { role: role, content: msg.content }
      end
    end

    def handle_escalation(conversation, response_text)
      # Remove [ESCALATE] tag for cleanliness if we want to send a final message
      clean_text = response_text.gsub("[ESCALATE]", "").strip
      
      if clean_text.present?
         Messages::MessageBuilder.new(
          nil,
          conversation,
          { content: clean_text, message_type: :outgoing }
        ).perform
      end

      # Unassign Bot -> Null (which might trigger auto-assign) 
      # OR directly trigger AutoAssignmentService
      
      AutoAssignment::AgentAssignmentService.new(conversation: conversation).perform
      
      # Ensure status is open
      conversation.update(status: :open)
    end
  end
end
