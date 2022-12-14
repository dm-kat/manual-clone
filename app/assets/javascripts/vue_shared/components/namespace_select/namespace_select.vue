<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import { __ } from '~/locale';

export const EMPTY_NAMESPACE_ID = -1;
export const i18n = {
  DEFAULT_TEXT: __('Select a new namespace'),
  DEFAULT_EMPTY_NAMESPACE_TEXT: __('No namespace'),
  GROUPS: __('Groups'),
  USERS: __('Users'),
};

const filterByName = (data, searchTerm = '') => {
  if (!searchTerm) {
    return data;
  }

  return data.filter((d) => d.humanName.toLowerCase().includes(searchTerm.toLowerCase()));
};

export default {
  name: 'NamespaceSelect',
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
    GlIntersectionObserver,
    GlLoadingIcon,
  },
  props: {
    groupNamespaces: {
      type: Array,
      required: false,
      default: () => [],
    },
    userNamespaces: {
      type: Array,
      required: false,
      default: () => [],
    },
    fullWidth: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultText: {
      type: String,
      required: false,
      default: i18n.DEFAULT_TEXT,
    },
    includeHeaders: {
      type: Boolean,
      required: false,
      default: true,
    },
    emptyNamespaceTitle: {
      type: String,
      required: false,
      default: i18n.DEFAULT_EMPTY_NAMESPACE_TEXT,
    },
    includeEmptyNamespace: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasNextPageOfGroups: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoadingMoreGroups: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSearchLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    shouldFilterNamespaces: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedNamespace: null,
    };
  },
  computed: {
    hasUserNamespaces() {
      return this.userNamespaces.length;
    },
    hasGroupNamespaces() {
      return this.groupNamespaces.length;
    },
    filteredGroupNamespaces() {
      if (!this.shouldFilterNamespaces) return this.groupNamespaces;
      if (!this.hasGroupNamespaces) return [];
      return filterByName(this.groupNamespaces, this.searchTerm);
    },
    filteredUserNamespaces() {
      if (!this.shouldFilterNamespaces) return this.userNamespaces;
      if (!this.hasUserNamespaces) return [];
      return filterByName(this.userNamespaces, this.searchTerm);
    },
    selectedNamespaceText() {
      return this.selectedNamespace?.humanName || this.defaultText;
    },
    filteredEmptyNamespaceTitle() {
      const { includeEmptyNamespace, emptyNamespaceTitle, searchTerm } = this;

      if (!includeEmptyNamespace) {
        return '';
      }
      if (!searchTerm) {
        return emptyNamespaceTitle;
      }

      return emptyNamespaceTitle.toLowerCase().includes(searchTerm.toLowerCase());
    },
  },
  watch: {
    searchTerm() {
      this.$emit('search', this.searchTerm);
    },
  },
  methods: {
    handleSelect(item) {
      this.selectedNamespace = item;
      this.searchTerm = '';
      this.$emit('select', item);
    },
    handleSelectEmptyNamespace() {
      this.handleSelect({ id: EMPTY_NAMESPACE_ID, humanName: this.emptyNamespaceTitle });
    },
  },
  i18n,
};
</script>
<template>
  <gl-dropdown :text="selectedNamespaceText" :block="fullWidth" data-qa-selector="namespaces_list">
    <template #header>
      <gl-search-box-by-type
        v-model.trim="searchTerm"
        :is-loading="isSearchLoading"
        data-qa-selector="namespaces_list_search"
      />
    </template>
    <div v-if="filteredEmptyNamespaceTitle">
      <gl-dropdown-item
        data-qa-selector="namespaces_list_item"
        @click="handleSelectEmptyNamespace()"
      >
        {{ emptyNamespaceTitle }}
      </gl-dropdown-item>
      <gl-dropdown-divider />
    </div>
    <div
      v-if="hasUserNamespaces"
      data-qa-selector="namespaces_list_users"
      data-testid="namespace-list-users"
    >
      <gl-dropdown-section-header v-if="includeHeaders">{{
        $options.i18n.USERS
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="item in filteredUserNamespaces"
        :key="item.id"
        data-qa-selector="namespaces_list_item"
        @click="handleSelect(item)"
        >{{ item.humanName }}</gl-dropdown-item
      >
    </div>
    <div
      v-if="hasGroupNamespaces"
      data-qa-selector="namespaces_list_groups"
      data-testid="namespace-list-groups"
    >
      <gl-dropdown-section-header v-if="includeHeaders">{{
        $options.i18n.GROUPS
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="item in filteredGroupNamespaces"
        :key="item.id"
        data-qa-selector="namespaces_list_item"
        @click="handleSelect(item)"
        >{{ item.humanName }}</gl-dropdown-item
      >
    </div>
    <gl-intersection-observer v-if="hasNextPageOfGroups" @appear="$emit('load-more-groups')">
      <gl-loading-icon v-if="isLoadingMoreGroups" class="gl-mb-3" size="sm" />
    </gl-intersection-observer>
  </gl-dropdown>
</template>
