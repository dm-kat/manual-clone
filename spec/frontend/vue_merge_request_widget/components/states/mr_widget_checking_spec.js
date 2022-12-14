import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import checkingComponent from '~/vue_merge_request_widget/components/states/mr_widget_checking.vue';

describe('MRWidgetChecking', () => {
  let Component;
  let vm;

  beforeEach(() => {
    Component = Vue.extend(checkingComponent);
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders loading icon', () => {
    expect(vm.$el.querySelector('.mr-widget-icon span').classList).toContain('gl-spinner');
  });

  it('renders information about merging', () => {
    expect(vm.$el.querySelector('.media-body').textContent.trim()).toEqual(
      'Checking if merge request can be merged…',
    );
  });
});
