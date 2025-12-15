<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import PageHeader from '../../components/PageHeader.vue';

export default {
  components: {
    PageHeader,
  },
  props: {
    onBack: {
      type: Function,
      default: () => {},
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      idInstance: '',
      apiTokenInstance: '',
      isCreating: false,
    };
  },
  validations: {
    inboxName: { required },
    idInstance: { required },
    apiTokenInstance: { required },
  },
  methods: {
    async createChannel() {
      this.isCreating = true;
      try {
        await this.$store.dispatch('inboxes/create', {
          name: this.inboxName,
          channel: {
            type: 'whatsapp_green_api',
            id_instance: this.idInstance,
            api_token_instance: this.apiTokenInstance,
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
      :header-title="'Green API Configuration'"
      :header-content="'Configure your Green API WhatsApp instance'"
    />
    <div class="flex flex-col w-full p-6">
      <form class="flex flex-col w-full gap-6" @submit.prevent="createChannel">
        <label>
          Inbox Name
          <input
            v-model="inboxName"
            type="text"
            placeholder="E.g. Support WhatsApp"
            class="w-full"
          />
        </label>

        <label>
          ID Instance
          <input
            v-model="idInstance"
            type="text"
            placeholder="Green API ID Instance"
            class="w-full"
          />
        </label>

        <label>
          API Token Instance
          <input
            v-model="apiTokenInstance"
            type="text"
            placeholder="Green API Token Instance"
            class="w-full"
          />
        </label>

        <div class="flex flex-row justify-end gap-2 w-full">
          <button class="button hollow secondary" @click.prevent="onBack">
            Cancel
          </button>
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
