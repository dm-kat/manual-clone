<script>
import { GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { humanizeRules } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/humanize';

import RequireApprovals from 'ee/security_orchestration/components/policy_drawer/require_approvals.vue';

export default {
  i18n: {
    policyDetails: s__('SecurityOrchestration|Edit policy'),
  },
  components: {
    GlLink,
    RequireApprovals,
  },
  inject: ['securityPoliciesPath'],
  props: {
    policy: {
      type: Object,
      required: true,
    },
  },
  computed: {
    policyAction() {
      return this.policy.actions.find((action) => action.type === 'require_approval');
    },
    humanizedRules() {
      return humanizeRules(this.policy.rules);
    },
    policyEditPath() {
      return `${this.securityPoliciesPath}/${encodeURIComponent(
        this.policy.name,
      )}/edit?type=scan_result_policy`;
    },
    approvers() {
      return this.policy.approvers;
    },
  },
};
</script>

<template>
  <tr v-if="policy.isSelected">
    <td colspan="4" class="gl-border-top-0! gl-pt-0!">
      <div
        class="gl-border-solid gl-border-1 gl-rounded-base gl-border-gray-100 gl-bg-gray-10 gl-py-4 gl-px-5"
      >
        <require-approvals :action="policyAction" :approvers="approvers" />
        <ul class="gl-mb-1">
          <li v-for="(rule, idx) in humanizedRules" :key="idx">
            {{ rule }}
          </li>
        </ul>
        <div class="gl-text-right">
          <gl-link :href="policyEditPath" target="_blank">
            {{ $options.i18n.policyDetails }}
          </gl-link>
        </div>
      </div>
    </td>
  </tr>
</template>
