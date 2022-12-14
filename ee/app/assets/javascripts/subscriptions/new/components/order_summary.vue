<script>
import { GlCard, GlIcon, GlCollapse, GlCollapseToggleDirective } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { sprintf, s__ } from '~/locale';
import { trackCheckout } from '~/google_tag_manager';
import formattingMixins from '../formatting_mixins';
import SummaryDetails from './order_summary/summary_details.vue';

export default {
  components: {
    SummaryDetails,
    GlCard,
    GlIcon,
    GlCollapse,
  },
  directives: {
    GlCollapseToggle: GlCollapseToggleDirective,
  },
  mixins: [formattingMixins],
  data() {
    return {
      summaryDetailsAreVisible: false,
    };
  },
  computed: {
    ...mapState(['numberOfUsers', 'selectedPlan']),
    ...mapGetters([
      'selectedPlanText',
      'totalAmount',
      'name',
      'usersPresent',
      'isGroupSelected',
      'isSelectedGroupPresent',
    ]),
    titleWithName() {
      return sprintf(this.$options.i18n.title, { name: this.name });
    },
  },
  mounted() {
    trackCheckout(this.selectedPlan, this.numberOfUsers);
  },
  i18n: {
    title: s__("Checkout|%{name}'s GitLab subscription"),
  },
};
</script>
<template>
  <gl-card
    v-if="!isGroupSelected || isSelectedGroupPresent"
    class="order-summary gl-display-flex gl-flex-direction-column gl-flex-grow-1"
  >
    <div class="gl-lg-display-none">
      <h4
        v-gl-collapse-toggle.summary-details
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-font-lg gl-my-0"
      >
        <div class="gl-display-flex gl-align-items-center">
          <gl-icon v-if="summaryDetailsAreVisible" name="chevron-down" class="gl-flex-shrink-0" />
          <gl-icon v-else name="chevron-right" class="gl-flex-shrink-0" />
          <span class="gl-ml-2">{{ titleWithName }}</span>
        </div>
        <span class="gl-ml-3">{{ formatAmount(totalAmount, usersPresent) }}</span>
      </h4>
      <gl-collapse id="summary-details" v-model="summaryDetailsAreVisible">
        <summary-details class="gl-mt-6" />
      </gl-collapse>
    </div>
    <div class="gl-display-none gl-lg-display-block" data-qa-selector="order_summary">
      <h4 class="gl-my-0 gl-font-lg" data-qa-selector="title">{{ titleWithName }}</h4>
      <summary-details class="gl-mt-6" />
    </div>
  </gl-card>
</template>
