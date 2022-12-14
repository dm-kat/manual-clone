<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { listen } from 'codesandbox-api';

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
  },
  props: {
    manager: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      currentBrowsingIndex: null,
      navigationStack: [],
      forwardNavigationStack: [],
      path: '',
      loading: true,
    };
  },
  computed: {
    backButtonDisabled() {
      return this.navigationStack.length <= 1;
    },
    forwardButtonDisabled() {
      return !this.forwardNavigationStack.length;
    },
  },
  mounted() {
    this.listener = listen((e) => {
      switch (e.type) {
        case 'urlchange':
          this.onUrlChange(e);
          break;
        case 'done':
          this.loading = false;
          break;
        default:
          break;
      }
    });
  },
  beforeDestroy() {
    this.listener();
  },
  methods: {
    onUrlChange(e) {
      const lastPath = this.path;

      this.path = e.url.replace(this.manager.bundlerURL, '') || '/';

      if (lastPath !== this.path) {
        this.currentBrowsingIndex =
          this.currentBrowsingIndex === null ? 0 : this.currentBrowsingIndex + 1;
        this.navigationStack.push(this.path);
      }
    },
    back() {
      const lastPath = this.path;

      this.visitPath(this.navigationStack[this.currentBrowsingIndex - 1]);

      this.forwardNavigationStack.push(lastPath);

      if (this.currentBrowsingIndex === 1) {
        this.currentBrowsingIndex = null;
        this.navigationStack = [];
      }
    },
    forward() {
      this.visitPath(this.forwardNavigationStack.splice(0, 1)[0]);
    },
    refresh() {
      this.visitPath(this.path);
    },
    visitPath(path) {
      // eslint-disable-next-line vue/no-mutating-props
      this.manager.iframe.src = `${this.manager.bundlerURL}${path}`;
    },
  },
};
</script>

<template>
  <header class="ide-preview-header d-flex align-items-center">
    <button
      :aria-label="s__('IDE|Back')"
      :disabled="backButtonDisabled"
      :class="{
        'disabled-content': backButtonDisabled,
      }"
      type="button"
      class="ide-navigator-btn d-flex align-items-center d-transparent border-0 bg-transparent"
      @click="back"
    >
      <gl-icon :size="24" name="chevron-left" class="m-auto" />
    </button>
    <button
      :aria-label="s__('IDE|Back')"
      :disabled="forwardButtonDisabled"
      :class="{
        'disabled-content': forwardButtonDisabled,
      }"
      type="button"
      class="ide-navigator-btn d-flex align-items-center d-transparent border-0 bg-transparent"
      @click="forward"
    >
      <gl-icon :size="24" name="chevron-right" class="m-auto" />
    </button>
    <button
      :aria-label="s__('IDE|Refresh preview')"
      type="button"
      class="ide-navigator-btn d-flex align-items-center d-transparent border-0 bg-transparent"
      @click="refresh"
    >
      <gl-icon :size="16" name="retry" class="m-auto" />
    </button>
    <div class="position-relative w-100 gl-ml-2">
      <input
        :value="path || '/'"
        type="text"
        class="ide-navigator-location form-control bg-white"
        readonly
      />
      <gl-loading-icon
        v-if="loading"
        size="sm"
        class="position-absolute ide-preview-loading-icon"
      />
    </div>
  </header>
</template>
