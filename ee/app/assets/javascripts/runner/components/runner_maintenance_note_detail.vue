<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RunnerDetail from '~/runner/components/runner_detail.vue';

export default {
  components: {
    RunnerDetail,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    shouldRender() {
      return this.glFeatures.runnerMaintenanceNote;
    },
  },
};
</script>

<template>
  <runner-detail v-if="shouldRender" :label="s__('Runners|Maintenance note')">
    <template v-if="value" #value>
      <div v-safe-html="value" class="md"></div>
    </template>
  </runner-detail>
</template>
