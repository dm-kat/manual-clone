import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import mrStatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

describe('MR widget status icon component', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const createWrapper = (props, mountFn = shallowMount) => {
    wrapper = mountFn(mrStatusIcon, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('while loading', () => {
    it('renders loading icon', () => {
      createWrapper({ status: 'loading' });

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('with status icon', () => {
    it('renders success status icon', () => {
      createWrapper({ status: 'success' }, mount);

      expect(wrapper.find('[data-testid="status_success-icon"]').exists()).toBe(true);
    });

    it('renders failed status icon', () => {
      createWrapper({ status: 'failed' }, mount);

      expect(wrapper.find('[data-testid="status_failed-icon"]').exists()).toBe(true);
    });
  });
});
