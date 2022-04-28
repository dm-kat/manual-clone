import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MinutesUsageProjectChart from 'ee/ci_minutes_usage/components/minutes_usage_project_chart.vue';
import { ciMinutesUsageMockData } from '../mock_data';

const {
  data: { ciMinutesUsage },
} = ciMinutesUsageMockData;

describe('Minutes usage by project chart component', () => {
  let wrapper;

  const findColumnChart = () => wrapper.findComponent(GlColumnChart);
  const findMonthDropdown = () => wrapper.findByTestId('minutes-usage-project-month-dropdown');
  const findAllMonthDropdownItems = () =>
    wrapper.findAllByTestId('minutes-usage-project-month-dropdown-item');
  const findYearDropdown = () => wrapper.findByTestId('minutes-usage-project-year-dropdown');
  const findAllYearDropdownItems = () =>
    wrapper.findAllByTestId('minutes-usage-project-year-dropdown-item');

  const createComponent = (usageData = ciMinutesUsage.nodes) => {
    wrapper = shallowMountExtended(MinutesUsageProjectChart, {
      propsData: {
        minutesUsageData: usageData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with CI minutes data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a column chart component with axis legends', () => {
      expect(findColumnChart().exists()).toBe(true);
      expect(findColumnChart().props('xAxisTitle')).toBe('Projects');
      expect(findColumnChart().props('yAxisTitle')).toBe('CI/CD minutes');
    });

    it('renders year dropdown component', () => {
      expect(findYearDropdown().exists()).toBe(true);
      expect(findYearDropdown().props('text')).toBe('2021');
    });

    it('renders month dropdown component', () => {
      expect(findMonthDropdown().exists()).toBe(true);
      expect(findMonthDropdown().props('text')).toBe('June');
    });

    it('renders only the months / years with available minutes data', () => {
      expect(findAllMonthDropdownItems().length).toBe(2);
      expect(findAllYearDropdownItems().length).toBe(2);
    });

    it('should contain a responsive attribute for the column chart', () => {
      expect(findColumnChart().attributes('responsive')).toBeDefined();
    });

    it('changes the selected year in the year dropdown', async () => {
      expect(findYearDropdown().props('text')).toBe('2021');

      findAllYearDropdownItems().at(1).vm.$emit('click');

      await nextTick();

      expect(findYearDropdown().props('text')).toBe('2022');
    });

    it('changes the selected month in the month dropdown', async () => {
      expect(findMonthDropdown().props('text')).toBe('June');

      findAllMonthDropdownItems().at(1).vm.$emit('click');

      await nextTick();

      expect(findMonthDropdown().props('text')).toBe('July');
    });
  });
});
