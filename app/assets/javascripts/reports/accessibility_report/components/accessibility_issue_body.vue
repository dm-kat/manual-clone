<script>
import { GlBadge, GlLink } from '@gitlab/ui';

export default {
  name: 'AccessibilityIssueBody',
  components: {
    GlBadge,
    GlLink,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    isNew: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    parsedTECHSCode() {
      /*
       * In issue code looks like "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail"
       * or "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent"
       *
       * The TECHS code is the "G18", "G168", "H91", etc. from the code which is used for the documentation.
       * Here we simply split the string on `.` and get the code in the 5th position
       */
      return this.issue.code?.split('.')[4];
    },
    learnMoreUrl() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `https://www.w3.org/TR/WCAG20-TECHS/${this.parsedTECHSCode || 'Overview'}.html`;
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description gl-mt-2 gl-mb-2">
    <div ref="accessibility-issue-description" class="report-block-list-issue-description-text">
      <gl-badge v-if="isNew" class="gl-mr-2" variant="danger">{{
        s__('AccessibilityReport|New')
      }}</gl-badge>
      <div>
        {{
          sprintf(
            s__(
              'AccessibilityReport|The accessibility scanning found an error of the following type: %{code}',
            ),
            { code: issue.code },
          )
        }}
        <gl-link ref="accessibility-issue-learn-more" :href="learnMoreUrl" target="_blank">{{
          s__('AccessibilityReport|Learn more')
        }}</gl-link>
      </div>
      {{ sprintf(s__('AccessibilityReport|Message: %{message}'), { message: issue.message }) }}
    </div>
  </div>
</template>
