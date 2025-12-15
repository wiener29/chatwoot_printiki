# Tasks

- [x] Analyze current architecture and n8n workflows <!-- id: 0 -->
- [x] Verify Enterprise edition unlock status <!-- id: 1 -->
- [x] Refine Implementation Plan <!-- id: 2 -->

## 1. Enterprise Unlock (Immediate)
- [x] Locate `BillingHelper` <!-- id: 3 -->
- [x] Create `config/initializers/02_unlock_enterprise.rb` patch <!-- id: 4 -->
- [x] Create Migration for `InstallationConfig` feature flags <!-- id: 5 -->
- [x] Verify Dashboard limits (Agents > 2) <!-- id: 6 -->

## 2. Infrastructure & Models
- [x] Create `Channel::WhatsappGreenApi` Model & Migration <!-- id: 7 -->
- [x] Create `Channel::Vk` Model & Migration <!-- id: 8 -->
- [x] Create `Channel::Max` Model & Migration <!-- id: 9 -->
- [x] Add `ai_agent_enabled` to `inboxes` Model & Migration <!-- id: 10 -->

## 3. Backend Implementation (AI)
- [x] Implement `Ai::GeminiService` <!-- id: 11 -->
- [x] Implement `AgentBots::AiResponseJob` <!-- id: 12 -->
- [x] Patch `Messages::CreateService` to trigger AI <!-- id: 13 -->
- [x] Implement Escalation Logic (`[ESCALATE]` token + AutoAssignment) <!-- id: 14 -->

## 4. Backend Implementation (Channels)
- [x] Implement `PreProcessingService` (Phone Check) <!-- id: 15 -->
- [x] Implement `Webhooks::WhatsappGreenApiController` <!-- id: 16 -->
- [x] Implement `Whatsapp::GreenApi::SendMessageService` <!-- id: 17 -->
- [x] Implement `Webhooks::VkController` <!-- id: 18 -->
- [x] Implement `Vk::SendMessageService` <!-- id: 19 -->
- [x] Implement `Webhooks::MaxController` <!-- id: 26 -->

## 5. Frontend Implementation
- [x] Update `Inbox` Settings UI (Add AI Toggle) <!-- id: 20 -->
- [x] Add GreenAPI Configuration Form <!-- id: 21 -->
- [x] Add VK Configuration Form <!-- id: 22 -->
- [x] Add MAX Configuration Form <!-- id: 27 -->

## 6. Verification
- [x] Test Enterprise Limits <!-- id: 23 -->
- [x] Test AI Response Flow <!-- id: 25 -->

## 7. Refinement (UI Config & Localization)
- [x] Migration: Add `ai_agent_model` & `ai_agent_prompt` to `inboxes` <!-- id: 28 -->
- [x] Backend: Update `InboxesController` & `Inbox` model <!-- id: 29 -->
- [x] API Service: Update `GeminiService` to use dynamic config from Inbox <!-- id: 30 -->
- [x] Frontend: Add Model & Prompt inputs to `Settings.vue` <!-- id: 31 -->
- [x] Localization: Fix English strings in `Settings.vue` (Russian) <!-- id: 32 -->
- [x] Localization: specific fix for `PreProcessingService` messages <!-- id: 33 -->
