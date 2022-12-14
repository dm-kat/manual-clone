import { shallowMount } from '@vue/test-utils';
import RepoDropdown from '~/projects/compare/components/repo_dropdown.vue';
import RevisionCard from '~/projects/compare/components/revision_card.vue';
import RevisionDropdown from '~/projects/compare/components/revision_dropdown.vue';
import { revisionCardDefaultProps as defaultProps } from './mock_data';

describe('RepoDropdown component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RevisionCard, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  const RevisionCardWrapper = () => wrapper.find('.revision-card');

  it('displays revision text', () => {
    expect(RevisionCardWrapper().text()).toContain(defaultProps.revisionText);
  });

  it('renders RepoDropdown component', () => {
    expect(wrapper.findAll(RepoDropdown).exists()).toBe(true);
  });

  it('renders RevisionDropdown component', () => {
    expect(wrapper.findAll(RevisionDropdown).exists()).toBe(true);
  });
});
