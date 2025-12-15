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
      instanceId: '',
      apiToken: '',
      isCreating: false,
    };
  },
  validations: {
    inboxName: { required },
    instanceId: { required },
    apiToken: { required },
  },
  methods: {
    async createChannel() {
      this.isCreating = true;
      try {
        await this.$store.dispatch('inboxes/create', {
          name: this.inboxName,
          channel: {
            type: 'max',
            instance_id: this.instanceId,
            api_token: this.apiToken,
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
      :header-title="'MAX Messenger Configuration'"
      :header-content="'Configure your MAX Messenger'"
    />
    <div class="flex flex-col w-full p-6">
      <form class="flex flex-col w-full gap-6" @submit.prevent="createChannel">
        <label>
          Inbox Name
          <input v-model="inboxName" type="text" placeholder="E.g. Support MAX" />
        </label>
        <label>
          Instance ID
          <input v-model="instanceId" type="text" placeholder="Instance ID" />
        </label>
        <label>
          API Token
          <input v-model="apiToken" type="text" placeholder="API Token" />
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
