<script>
import { GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlTooltip,
  },
  props: {
    healthStatus: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  computed: {
    hasHealthStatus() {
      const { issuesOnTrack, issuesNeedingAttention, issuesAtRisk } = this.healthStatus;
      const totalHealthStatuses = issuesOnTrack + issuesNeedingAttention + issuesAtRisk;
      return totalHealthStatuses > 0;
    },
  },
};
</script>

<template>
  <div
    v-if="hasHealthStatus"
    ref="healthStatus"
    class="health-status d-inline-flex align-items-center"
  >
    <gl-tooltip :target="() => $refs.healthStatus" placement="top">
      <span
        ><strong>{{ healthStatus.issuesOnTrack }}</strong
        >&nbsp;<span>{{ __('issues on track') }}</span
        >,</span
      ><br />
      <span
        ><strong>{{ healthStatus.issuesNeedingAttention }}</strong
        >&nbsp;<span>{{ __('issues need attention') }}</span
        >,</span
      ><br />
      <span
        ><strong>{{ healthStatus.issuesAtRisk }}</strong
        >&nbsp;<span>{{ __('issues at risk') }}</span></span
      >
    </gl-tooltip>

    <span class="gl-label gl-label-text-dark gl-label-sm status-on-track gl-mr-2">
      <span class="gl-label-text">
        {{ healthStatus.issuesOnTrack }}
      </span>
    </span>
    <span class="gl-mr-2 mr-md-2 gl-text-gray-500 health-label-long gl-display-none!">
      {{ __('issues on track') }}
    </span>
    <span
      class="gl-mr-2 mr-md-2 gl-text-gray-500 gl-str-truncated health-label-short gl-display-none!"
      >{{ __('on track') }}</span
    >

    <span class="gl-label gl-label-text-dark gl-label-sm status-needs-attention gl-mr-2">
      <span class="gl-label-text">
        {{ healthStatus.issuesNeedingAttention }}
      </span>
    </span>
    <span class="gl-mr-2 mr-md-2 gl-text-gray-500 health-label-long gl-display-none!">
      {{ __('issues need attention') }}
    </span>
    <span
      class="gl-mr-2 mr-md-2 gl-text-gray-500 gl-str-truncated health-label-short gl-display-none!"
      >{{ __('need attention') }}</span
    >

    <span class="gl-label gl-label-text-dark gl-label-sm status-at-risk gl-mr-2">
      <span class="gl-label-text">
        {{ healthStatus.issuesAtRisk }}
      </span>
    </span>
    <span class="gl-text-gray-500 health-label-long gl-display-none!">
      {{ __('issues at risk') }}
    </span>
    <span class="gl-text-gray-500 gl-str-truncated health-label-short gl-display-none!">
      {{ __('at risk') }}
    </span>
  </div>
</template>
