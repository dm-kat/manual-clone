<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import { __, s__ } from '~/locale';
import DuplicateDashboardForm from './duplicate_dashboard_form.vue';

const events = {
  dashboardDuplicated: 'dashboardDuplicated',
};

export default {
  components: { GlAlert, GlModal, DuplicateDashboardForm },
  props: {
    defaultBranch: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      alert: null,
      loading: false,
      form: {},
    };
  },
  computed: {
    ...mapGetters('monitoringDashboard', ['selectedDashboard']),
    okButtonText() {
      return this.loading ? s__('Metrics|Duplicating...') : s__('Metrics|Duplicate');
    },
    actionPrimaryProps() {
      return {
        text: this.okButtonText,
        attributes: {
          loading: this.loading,
          variant: 'confirm',
        },
      };
    },
    actionCancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },
  methods: {
    ...mapActions('monitoringDashboard', ['duplicateSystemDashboard']),
    ok(bvModalEvt) {
      // Prevent modal from hiding in case submit fails
      bvModalEvt.preventDefault();

      this.loading = true;
      this.alert = null;
      this.duplicateSystemDashboard(this.form)
        .then((createdDashboard) => {
          this.loading = false;
          this.alert = null;

          // Trigger hide modal as submit is successful
          this.$refs.duplicateDashboardModal.hide();

          // Dashboards in the default branch become available immediately.
          // Not so in other branches, so we refresh the current dashboard
          const dashboard =
            this.form.branch === this.defaultBranch ? createdDashboard : this.selectedDashboard;
          this.$emit(events.dashboardDuplicated, dashboard);
        })
        .catch((error) => {
          this.loading = false;
          this.alert = error;
        });
    },
    hide() {
      this.alert = null;
    },
    formChange(form) {
      this.form = form;
    },
  },
};
</script>

<template>
  <gl-modal
    ref="duplicateDashboardModal"
    :modal-id="modalId"
    :title="s__('Metrics|Duplicate dashboard')"
    :action-primary="actionPrimaryProps"
    :action-cancel="actionCancelProps"
    @ok="ok"
    @hide="hide"
  >
    <gl-alert v-if="alert" class="mb-3" variant="danger" @dismiss="alert = null">
      {{ alert }}
    </gl-alert>
    <duplicate-dashboard-form
      :dashboard="selectedDashboard"
      :default-branch="defaultBranch"
      @change="formChange"
    />
  </gl-modal>
</template>
