import { GlDrawer } from '@gitlab/ui';
import MergeRequestDrawer from 'ee/compliance_dashboard/components/drawer.vue';
import Project from 'ee/compliance_dashboard/components/drawer_sections/project.vue';
import { complianceFramework } from 'ee_jest/vue_shared/components/compliance_framework_label/mock_data';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMergeRequests } from '../mock_data';

describe('MergeRequestDrawer component', () => {
  let wrapper;
  const mergeRequest = createMergeRequests({
    count: 1,
    props: {
      compliance_management_framework: complianceFramework,
    },
  })[0];

  const findTitle = () => wrapper.findByTestId('dashboard-drawer-title');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findProject = () => wrapper.findComponent(Project);

  const createComponent = (props) => {
    return shallowMountExtended(MergeRequestDrawer, {
      propsData: {
        mergeRequest,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when closed', () => {
    beforeEach(() => {
      wrapper = createComponent({ showDrawer: false });
    });

    it('the drawer is not shown', () => {
      expect(findDrawer().props('open')).toBe(false);
    });

    it('the sections are not mounted', () => {
      expect(findProject().exists()).toBe(false);
    });
  });

  describe('when open', () => {
    beforeEach(() => {
      wrapper = createComponent({ showDrawer: true });
    });

    it('the drawer is shown', () => {
      expect(findDrawer().props('open')).toBe(true);
    });

    it('has the drawer title', () => {
      expect(findTitle().text()).toEqual(mergeRequest.title);
    });

    it('has the project section', () => {
      expect(findProject().props()).toStrictEqual({
        avatarUrl: mergeRequest.project.avatar_url,
        complianceFramework,
        name: mergeRequest.project.name,
        url: mergeRequest.project.web_url,
      });
    });
  });
});
