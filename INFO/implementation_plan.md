# Implementaton Plan: AI Agent, Custom Channels & Enterprise Unlock

**Goal**: Full integration of first-line AI Agent (Gemini), addition of WhatsApp (GreenAPI), VK, MAX channels, and complete removal of Enterprise restrictions.

## User Review Required
> [!IMPORTANT]
> **API Credentials**: Please update `.env` with:
> - `GEMINI_API_KEY`: Google Gemini API Key.
> - `GREEN_API_ID_INSTANCE`: GreenAPI Instance ID.
> - `GREEN_API_API_TOKEN_INSTANCE`: GreenAPI Token.
> - `VK_GROUP_ID` & `VK_CONFIRMATION_TOKEN` & `VK_SECRET_KEY`: VK Community settings.

> [!WARNING]
> **Enterprise Unlock**: I will verify and patch the `BillingHelper` to bypass all license checks. This will enable unlimited agents/inboxes unless hardware limits are reached.

## 1. Enterprise Feature Unlock (High Priority)
Ensure full Enterprise functionality without license keys.

*   **Verification**: Check `ChatwootApp.enterprise?` (Confirmed: True).
*   **Logic Patching**:
    *   **Limits & Billing**: Locate `BillingHelper` (Likely in `app/helpers/billing_helper.rb`).
    *   **Action**: Create a monkey-patch `config/initializers/02_unlock_enterprise.rb` to override:
        *   `BillingHelper#default_plan?` -> returns `false` (Forces use of `Account.usage_limits`).
        *   `BillingHelper#subscribed?` -> returns `true`.
    *   **Features**: Check `InstallationConfig` table.
    *   **Action**: Create a structured Migration or Rake task to:
        *   Set `ACCOUNT_LEVEL_FEATURE_DEFAULTS` to enable ALL features (including Premium).
        *   Update existing accounts to enable all features.

## 2. Inbound Channel "Pre-processing" Architecture
Implement a unified interceptor pattern to handle "Pre-registration" logic (collecting phone numbers before creating conversations).

*   **Core Logic**: `app/services/channels/pre_processing_service.rb`
    *   **Input**: `contact_identifier` (e.g., telegram_chat_id), `payload`, `channel_type`.
    *   **Flow**:
        1.  Find Contact by identifier.
        2.  If Contact exists AND has phone -> Return `:proceed`.
        3.  If Contact missing OR no phone ->
            *   Analyze payload (is it a phone number sharing message?).
            *   If YES -> Update Contact -> Return `:proceed`.
            *   If NO -> Return `:halt` with reply_action (e.g., "Please share contact").

## 3. Communication Channels Implementation

### 3.1 WhatsApp (GreenAPI)
*   **Model**: `app/models/channel/whatsapp_green_api.rb`
    *   Attributes: `instance_id`, `api_token`.
*   **Receiver**: `app/controllers/api/v1/webhooks/green_api_controller.rb`
    *   Endpoint: `POST /api/v1/webhooks/green_api/:id`
    *   Map incoming webhooks to Chatwoot events.
*   **Sender**: `app/services/whatsapp/green_api/send_message_service.rb`
    *   Implement `perform` method to call GreenAPI `SendMessage`.

### 3.2 VKontakte (VK)
*   **Model**: `app/models/channel/vk.rb`
    *   Attributes: `group_id`, `access_token`, `confirmation_token`, `secret_key`.
*   **Receiver**: `app/controllers/api/v1/webhooks/vk_controller.rb`
    *   Endpoint: `POST /api/v1/webhooks/vk` (Callback API).
    *   Handle `confirmation` event (return token).
    *   Handle `message_new` -> trigger `PreProcessingService`.
*   **Sender**: `app/services/vk/send_message_service.rb`
    *   Use `vk-ruby` or raw HTTP. Support attachments.

### 3.3 MAX Messenger
*   **Status**: Skeleton implementation pending documentation.
*   **Files**: `app/models/channel/max.rb`, `app/controllers/api/v1/webhooks/max_controller.rb`.

## 4. AI Agent Integration (First Line)

### 4.1 Configuration
*   **Database**: Migration to add `ai_agent_enabled` (boolean, default: false) to `inboxes` table.
*   **API**: Add `ai_agent_enabled` to `InboxesController` permitted params and serializer (`app/views/api/v1/inboxes/show.json.jbuilder`).
*   **UI**: Update `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue` to include toggle.

### 4.2 AI Service (Gemini)
*   **File**: `app/services/ai/gemini_service.rb`
*   **Function**: `generate_response(messages_history)`
*   **Implementation**: Use `gemini-pro` model via Google AI Studio API.

### 4.3 Integration Logic (The Brain)
*   **Hook**: Modify `app/services/messages/create_service.rb` (Line ~120, after message creation).
*   **Logic**:
    1.  Check `inbox.ai_agent_enabled?`.
    2.  Check if `conversation.assignee` is nil OR is the AI Bot.
    3.  If YES -> Trigger `AgentBots::ai_response_job.rb` (Async).
*   **Job**: `app/jobs/agent_bots/ai_response_job.rb`
    1.  Call `Ai::GeminiService`.
    2.  Create outgoing message from AI.

### 4.4 Escalation (Handover)
*   **Trigger**:
    *   **Manual**: Agent clicks "Join" or "Assign".
    *   **AI Decision**: AI replies with special token `[ESCALATE]`.
*   **Mechanism**:
    *   Unassign AI Bot.
    *   Call `AutoAssignmentService.new(conversation).perform`.
    *   Update Conversation status to `open`.

## Checklists & Tasks
See `INFO/tasks.md` for granular tracking.
