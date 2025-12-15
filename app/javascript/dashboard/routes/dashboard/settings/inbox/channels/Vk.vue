<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import PageHeader from '../../components/PageHeader.vue';

export default {
  components: {
    PageHeader,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      groupId: '',
      accessToken: '',
      confirmationToken: '',
      secretKey: '',
      isCreating: false,
    };
  },
  validations: {
    inboxName: { required },
    groupId: { required },
    accessToken: { required },
    confirmationToken: { required },
  },
  methods: {
    async createChannel() {
      this.isCreating = true;
      try {
        await this.$store.dispatch('inboxes/create', {
          name: this.inboxName,
          channel: {
            type: 'vk',
            group_id: this.groupId,
            access_token: this.accessToken,
            confirmation_token: this.confirmationToken,
            secret_key: this.secretKey,
          },
        });
        this.$router.replace({
          name: 'settings_inboxes_list',
        });
        useAlert(this.$t('INBOX_MGMT.ADD.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.ADD.API.ERROR_MESSAGE'));
      } finally {
        this.isCreating = false;
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col w-full h-full my-6 bg-white dark:bg-slate-900 border border-slate-50 dark:border-slate-800 rounded-lg shadow-sm overflow-hidden">
    <PageHeader
      :header-title="'VK Configuration'"
      :header-content="'Configure your VK Community'"
    />
    <div class="flex flex-col w-full p-6">
      <form class="flex flex-col w-full gap-6" @submit.prevent="createChannel">
        <label>
          Inbox Name
          <input v-model="inboxName" type="text" placeholder="E.g. Support VK" />
        </label>
        <label>
          Group ID
          <input v-model="groupId" type="text" placeholder="VK Group ID" />
        </label>
        <label>
          Access Token
          <input v-model="accessToken" type="text" placeholder="VK Access Token" />
        </label>
        <label>
          Confirmation Token
          <input v-model="confirmationToken" type="text" placeholder="VK Confirmation Token" />
        </label>
        <label>
          Secret Key
          <input v-model="secretKey" type="text" placeholder="Optional Secret Key" />
        </label>
        <div class="flex flex-row justify-end gap-2 w-full">
          <button
            class="button primary"
            type="submit"
            :disabled="v$.$invalid || isCreating"
          >
            {{ isCreating ? 'Creating...' : 'Create Inbox' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
