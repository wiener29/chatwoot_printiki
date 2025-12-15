class EnableAllEnterpriseFeatures < ActiveRecord::Migration[7.0]
  def up
    # Load feature definition
    features_file = Rails.root.join('config/features.yml')
    return unless File.exist?(features_file)

    all_features = YAML.safe_load(File.read(features_file))
    
    # 1. Update Global Defaults in InstallationConfig
    # We construct the value that matches the expected schema for ACCOUNT_LEVEL_FEATURE_DEFAULTS
    enabled_features_config = all_features.map do |f| 
      { 'name' => f['name'], 'enabled' => true }
    end

    config = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    # Use update_column to bypass any validations/locks if possible, or just standard save
    config.serialized_value = { value: enabled_features_config }
    config.locked = false
    config.save!

    puts "Updated ACCOUNT_LEVEL_FEATURE_DEFAULTS to enable all features."

    # 2. Update Existing Accounts
    # We iterate over all accounts and enable every feature flag.
    # Feature flags are stored using FlagShihTzu bitmask on 'feature_flags' column.
    
    Account.find_each do |account|
      all_features.each do |feature|
        # Featurable module provides dynamic methods: feature_name=
        method_name = "feature_#{feature['name']}="
        if account.respond_to?(method_name)
          account.send(method_name, true)
        end
      end
      account.save!
    end
    
    puts "Updated all existing accounts with full feature access."
  end

  def down
    # We do not revert this as it would disable features for users
  end
end
