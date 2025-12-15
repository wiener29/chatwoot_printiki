module Enterprise::Account::PlanUsageAndLimits
  CAPTAIN_RESPONSES = 'captain_responses'.freeze
  CAPTAIN_DOCUMENTS = 'captain_documents'.freeze
  CAPTAIN_RESPONSES_USAGE = 'captain_responses_usage'.freeze
  CAPTAIN_DOCUMENTS_USAGE = 'captain_documents_usage'.freeze

  def usage_limits
    {
      agents: ChatwootApp.max_limit.to_i,
      inboxes: ChatwootApp.max_limit.to_i,
      captain: {
        documents: {
          total_count: ChatwootApp.max_limit,
          current_available: ChatwootApp.max_limit,
          consumed: 0
        },
        responses: {
          total_count: ChatwootApp.max_limit,
          current_available: ChatwootApp.max_limit,
          consumed: 0
        }
      }
    }
  end

  def increment_response_usage
    current_usage = custom_attributes[CAPTAIN_RESPONSES_USAGE].to_i || 0
    custom_attributes[CAPTAIN_RESPONSES_USAGE] = current_usage + 1
    save
  end

  def reset_response_usage
    custom_attributes[CAPTAIN_RESPONSES_USAGE] = 0
    save
  end

  def update_document_usage
    # this will ensure that the document count is always accurate
    custom_attributes[CAPTAIN_DOCUMENTS_USAGE] = captain_documents.count
    save
  end

  def subscribed_features
    # Возвращаем все premium функции без проверки плана
    premium_features = YAML.safe_load(Rails.root.join('config/features.yml').read)
                           .select { |f| f['premium'] }
                           .map { |f| f['name'] }

    return premium_features unless premium_features.empty?

    # Fallback на оригинальную логику, если что-то пойдет не так
    plan_features = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLAN_FEATURES')&.value
    return [] if plan_features.blank?

    plan_features[plan_name]
  end

  def captain_monthly_limit
    default_limits = default_captain_limits

    {
      documents: self[:limits][CAPTAIN_DOCUMENTS] || default_limits['documents'],
      responses: self[:limits][CAPTAIN_RESPONSES] || default_limits['responses']
    }.with_indifferent_access
  end

  private

  def get_captain_limits(type)
    total_count = captain_monthly_limit[type.to_s].to_i

    consumed = if type == :documents
                 custom_attributes[CAPTAIN_DOCUMENTS_USAGE].to_i || 0
               else
                 custom_attributes[CAPTAIN_RESPONSES_USAGE].to_i || 0
               end

    consumed = 0 if consumed.negative?

    {
      total_count: total_count,
      current_available: (total_count - consumed).clamp(0, total_count),
      consumed: consumed
    }
  end

  def default_captain_limits
    # Всегда возвращаем максимальные лимиты без проверки плана
    { documents: ChatwootApp.max_limit, responses: ChatwootApp.max_limit }.with_indifferent_access
  end

  def plan_name
    custom_attributes['plan_name']
  end

  def agent_limits
    # Всегда возвращаем максимальное количество агентов
    ChatwootApp.max_limit
  end

  def get_limits(limit_name)
    # Всегда возвращаем максимальный лимит без проверки конфигурации
    ChatwootApp.max_limit
  end

  def validate_limit_keys
    errors.add(:limits, ': Invalid data') unless self[:limits].is_a? Hash
    self[:limits] = {} if self[:limits].blank?

    limit_schema = {
      'type' => 'object',
      'properties' => {
        'inboxes' => { 'type': 'number' },
        'agents' => { 'type': 'number' },
        'captain_responses' => { 'type': 'number' },
        'captain_documents' => { 'type': 'number' }
      },
      'required' => [],
      'additionalProperties' => false
    }

    errors.add(:limits, ': Invalid data') unless JSONSchemer.schema(limit_schema).valid?(self[:limits])
  end
end
