import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import IterationSelect from 'ee/boards/components/iteration_select.vue';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { boardObj } from 'jest/boards/mock_data';

import defaultStore from '~/boards/stores';
import searchIterationQuery from 'ee/issues/list/queries/search_iterations.query.graphql';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';
import { mockIterationsResponse, mockIterations } from './mock_data';

Vue.use(VueApollo);

describe('Iteration select component', () => {
  let wrapper;
  let fakeApollo;

  const selectedText = () => wrapper.findByTestId('selected-iteration').text();
  const findEditButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(DropdownWidget);

  const iterationsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockIterationsResponse);

  const createStore = () => {
    return new Vuex.Store({
      ...defaultStore,
      getters: {
        isGroupBoard: () => true,
        isProjectBoard: () => false,
      },
      actions: {
        setError: jest.fn(),
      },
    });
  };

  const createComponent = ({ props = {} } = {}) => {
    const store = createStore();
    fakeApollo = createMockApollo([[searchIterationQuery, iterationsQueryHandlerSuccess]]);
    wrapper = shallowMountExtended(IterationSelect, {
      store,
      apolloProvider: fakeApollo,
      propsData: {
        board: boardObj,
        canEdit: true,
        ...props,
      },
      provide: {
        fullPath: 'gitlab-org',
      },
      stubs: {
        GlDropdown,
        GlDropdownItem,
      },
    });

    // We need to mock out `showDropdown` which
    // invokes `show` method of BDropdown used inside GlDropdown.
    jest.spyOn(wrapper.vm, 'showDropdown').mockImplementation();
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  describe('when not editing', () => {
    beforeEach(() => {
      createComponent();
    });

    it('defaults to Any iteration', () => {
      expect(selectedText()).toContain('Any iteration');
    });

    it('skips the queries and does not render dropdown', () => {
      expect(iterationsQueryHandlerSuccess).not.toHaveBeenCalled();
      expect(findDropdown().isVisible()).toBe(false);
    });

    it('renders selected iteration', async () => {
      findEditButton().vm.$emit('click');

      findDropdown().vm.$emit('set-option', mockIterations[1]);
      await nextTick();

      expect(selectedText()).toContain(mockIterations[1].title);
    });

    it('shows Edit button if canEdit is true', () => {
      expect(findEditButton().exists()).toBe(true);
    });
  });

  describe('when editing', () => {
    beforeEach(() => {
      createComponent();
    });

    it('trigger query and renders dropdown with passed iterations', async () => {
      findEditButton().vm.$emit('click');
      await waitForPromises();
      expect(iterationsQueryHandlerSuccess).toHaveBeenCalled();

      expect(findDropdown().isVisible()).toBe(true);
      expect(findDropdown().props('groupedOptions')).toHaveLength(2);
    });
  });

  describe('canEdit', () => {
    beforeEach(() => {
      createComponent({ props: { canEdit: false } });
    });

    it('hides Edit button if false', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });
});
