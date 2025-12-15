class AddAiAgentEnabledToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :ai_agent_enabled, :boolean, default: false
  end
end
