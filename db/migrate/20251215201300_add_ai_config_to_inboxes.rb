class AddAiConfigToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :ai_agent_model, :string, default: 'gemini-1.5-pro'
    add_column :inboxes, :ai_agent_prompt, :text
  end
end
