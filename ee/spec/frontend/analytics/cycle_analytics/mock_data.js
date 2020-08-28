import { uniq } from 'lodash';
import { TEST_HOST } from 'helpers/test_constants';
import { getJSONFixture } from 'helpers/fixtures';
import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import {
  DEFAULT_DAYS_IN_PAST,
  TASKS_BY_TYPE_SUBJECT_ISSUE,
} from 'ee/analytics/cycle_analytics/constants';
import { toYmd } from 'ee/analytics/shared/utils';
import {
  getTasksByTypeData,
  transformRawTasksByTypeData,
  transformStagesForPathNavigation,
} from 'ee/analytics/cycle_analytics/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getDateInPast, getDatesInRange } from '~/lib/utils/datetime_utility';

const fixtureEndpoints = {
  customizableCycleAnalyticsStagesAndEvents: 'analytics/value_stream_analytics/stages.json', // customizable stages and events endpoint
  stageEvents: stage => `analytics/value_stream_analytics/stages/${stage}/records.json`,
  stageMedian: stage => `analytics/value_stream_analytics/stages/${stage}/median.json`,
  recentActivityData: 'analytics/value_stream_analytics/summary.json',
  timeMetricsData: 'analytics/value_stream_analytics/time_summary.json',
  groupLabels: 'api/group_labels.json',
};

export const endpoints = {
  groupLabels: /groups\/[A-Z|a-z|\d|\-|_]+\/-\/labels.json/,
  recentActivityData: /analytics\/value_stream_analytics\/summary/,
  timeMetricsData: /analytics\/value_stream_analytics\/time_summary/,
  durationData: /analytics\/value_stream_analytics\/value_streams\/\d+\/stages\/\d+\/duration_chart/,
  stageData: /analytics\/value_stream_analytics\/value_streams\/\d+\/stages\/\d+\/records/,
  stageMedian: /analytics\/value_stream_analytics\/value_streams\/\d+\/stages\/\d+\/median/,
  baseStagesEndpoint: /analytics\/value_stream_analytics\/value_streams\/\d+\/stages$/,
  tasksByTypeData: /analytics\/type_of_work\/tasks_by_type/,
  tasksByTypeTopLabelsData: /analytics\/type_of_work\/tasks_by_type\/top_labels/,
  valueStreamData: /analytics\/value_stream_analytics\/value_streams/,
};

export const valueStreams = [{ id: 1, name: 'Value stream 1' }, { id: 2, name: 'Value stream 2' }];

export const groupLabels = getJSONFixture(fixtureEndpoints.groupLabels).map(
  convertObjectPropsToCamelCase,
);

export const group = {
  id: 1,
  name: 'foo',
  path: 'foo',
  full_path: 'foo',
  avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
};

export const selectedGroup = convertObjectPropsToCamelCase(group, { deep: true });

const getStageByTitle = (stages, title) =>
  stages.find(stage => stage.title && stage.title.toLowerCase().trim() === title) || {};

export const recentActivityData = getJSONFixture(fixtureEndpoints.recentActivityData);
export const timeMetricsData = getJSONFixture(fixtureEndpoints.timeMetricsData);

export const customizableStagesAndEvents = getJSONFixture(
  fixtureEndpoints.customizableCycleAnalyticsStagesAndEvents,
);

const dummyState = {};

// prepare the raw stage data for our components
mutations[types.RECEIVE_GROUP_STAGES_SUCCESS](dummyState, customizableStagesAndEvents.stages);

export const issueStage = getStageByTitle(dummyState.stages, 'issue');
export const planStage = getStageByTitle(dummyState.stages, 'plan');
export const reviewStage = getStageByTitle(dummyState.stages, 'review');
export const codeStage = getStageByTitle(dummyState.stages, 'code');
export const testStage = getStageByTitle(dummyState.stages, 'test');
export const stagingStage = getStageByTitle(dummyState.stages, 'staging');
export const totalStage = getStageByTitle(dummyState.stages, 'total');

export const allowedStages = [issueStage, planStage, codeStage];

const deepCamelCase = obj => convertObjectPropsToCamelCase(obj, { deep: true });

export const defaultStages = ['issue', 'plan', 'review', 'code', 'test', 'staging', 'production'];

const stageFixtures = defaultStages.reduce((acc, stage) => {
  const events = getJSONFixture(fixtureEndpoints.stageEvents(stage));
  return {
    ...acc,
    [stage]: events,
  };
}, {});

export const stageMedians = defaultStages.reduce((acc, stage) => {
  const { value } = getJSONFixture(fixtureEndpoints.stageMedian(stage));
  return {
    ...acc,
    [stage]: value,
  };
}, {});

export const stageMediansWithNumericIds = defaultStages.reduce((acc, stage) => {
  const { value } = getJSONFixture(fixtureEndpoints.stageMedian(stage));
  const { id } = getStageByTitle(dummyState.stages, stage);
  return {
    ...acc,
    [id]: value,
  };
}, {});

export const endDate = new Date(2019, 0, 14);
export const startDate = getDateInPast(endDate, DEFAULT_DAYS_IN_PAST);

export const rawIssueEvents = stageFixtures.issue;
export const issueEvents = deepCamelCase(stageFixtures.issue);
export const planEvents = deepCamelCase(stageFixtures.plan);
export const reviewEvents = deepCamelCase(stageFixtures.review);
export const codeEvents = deepCamelCase(stageFixtures.code);
export const testEvents = deepCamelCase(stageFixtures.test);
export const stagingEvents = deepCamelCase(stageFixtures.staging);
export const totalEvents = deepCamelCase(stageFixtures.production);
export const rawCustomStage = {
  title: 'Coolest beans stage',
  hidden: false,
  legend: '',
  description: '',
  id: 18,
  custom: true,
  start_event_identifier: 'issue_first_mentioned_in_commit',
  end_event_identifier: 'issue_first_added_to_board',
};

export const medians = stageMedians;

export const rawCustomStageEvents = customizableStagesAndEvents.events;
export const camelCasedStageEvents = rawCustomStageEvents.map(deepCamelCase);

export const customStageLabelEvents = camelCasedStageEvents.filter(ev => ev.type === 'label');
export const customStageStartEvents = camelCasedStageEvents.filter(ev => ev.canBeStartEvent);

// get all the possible stop events
const allowedEndEventIds = new Set(customStageStartEvents.flatMap(e => e.allowedEndEvents));
export const customStageStopEvents = camelCasedStageEvents.filter(ev =>
  allowedEndEventIds.has(ev.identifier),
);

export const customStageEvents = uniq(
  [...customStageStartEvents, ...customStageStopEvents],
  false,
  ev => ev.identifier,
);

export const labelStartEvent = customStageLabelEvents[0];
export const labelStopEvent = customStageLabelEvents.find(
  ev => ev.identifier === labelStartEvent.allowedEndEvents[0],
);

export const rawCustomStageFormErrors = {
  name: ['is reserved', 'cant be blank'],
  start_event_identifier: ['cant be blank'],
};

export const customStageFormErrors = convertObjectPropsToCamelCase(rawCustomStageFormErrors);

const dateRange = getDatesInRange(startDate, endDate, toYmd);

export const apiTasksByTypeData = getJSONFixture('analytics/type_of_work/tasks_by_type.json').map(
  labelData => {
    // add data points for our mock date range
    const maxValue = 10;
    const series = dateRange.map(date => [date, Math.floor(Math.random() * Math.floor(maxValue))]);
    return {
      ...labelData,
      series,
    };
  },
);

export const rawTasksByTypeData = transformRawTasksByTypeData(apiTasksByTypeData);
export const transformedTasksByTypeData = getTasksByTypeData(apiTasksByTypeData);

export const transformedStagePathData = transformStagesForPathNavigation({
  stages: allowedStages,
  medians,
  selectedStage: issueStage,
});

export const tasksByTypeData = {
  seriesNames: ['Cool label', 'Normal label'],
  data: [[0, 1, 2], [5, 2, 3], [2, 4, 1]],
  groupBy: ['Group 1', 'Group 2', 'Group 3'],
};

export const taskByTypeFilters = {
  selectedGroup: {
    id: 22,
    name: 'Gitlab Org',
    fullName: 'Gitlab Org',
    fullPath: 'gitlab-org',
  },
  selectedProjectIds: [],
  startDate: new Date('2019-12-11'),
  endDate: new Date('2020-01-10'),
  subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
  selectedLabelIds: [1, 2, 3],
};

export const rawDurationData = [
  {
    duration_in_seconds: 1234000,
    finished_at: '2019-01-01T00:00:00.000Z',
  },
  {
    duration_in_seconds: 4321000,
    finished_at: '2019-01-02T00:00:00.000Z',
  },
];

export const transformedDurationData = [
  {
    slug: 1,
    selected: true,
    data: rawDurationData,
  },
  {
    slug: 2,
    selected: true,
    data: rawDurationData,
  },
];

export const flattenedDurationData = [
  { duration_in_seconds: 1234000, finished_at: '2019-01-01' },
  { duration_in_seconds: 4321000, finished_at: '2019-01-02' },
  { duration_in_seconds: 1234000, finished_at: '2019-01-01' },
  { duration_in_seconds: 4321000, finished_at: '2019-01-02' },
];

export const durationChartPlottableData = [
  ['2019-01-01', 29, '2019-01-01'],
  ['2019-01-02', 100, '2019-01-02'],
];

export const rawDurationMedianData = [
  {
    duration_in_seconds: 1234000,
    finished_at: '2018-12-01T00:00:00.000Z',
  },
  {
    duration_in_seconds: 4321000,
    finished_at: '2018-12-02T00:00:00.000Z',
  },
];

export const selectedProjects = [
  {
    id: 1,
    name: 'cool project',
    pathWithNamespace: 'group/cool-project',
    avatarUrl: null,
  },
  {
    id: 2,
    name: 'another cool project',
    pathWithNamespace: 'group/another-cool-project',
    avatarUrl: null,
  },
];

// Value returned from JSON fixture is 345600 for issue stage which equals 4d
export const pathNavIssueMetric = '4d';

export const filterMilestones = [
  { id: 1, title: 'None', name: 'Any' },
  { id: 101, title: 'Any', name: 'None' },
  { id: 1001, title: 'v1.0', name: 'v1.0' },
  { id: 10101, title: 'v0.0', name: 'v0.0' },
];

export const filterUsers = [
  {
    id: 31,
    name: 'VSM User2',
    username: 'vsm-user-2-1589776313',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/762398957a8c6e04eed16da88098899d?s=80\u0026d=identicon',
    web_url: 'http://127.0.0.1:3001/vsm-user-2-1589776313',
    access_level: 30,
    expires_at: null,
  },
  {
    id: 32,
    name: 'VSM User3',
    username: 'vsm-user-3-1589776313',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/f78932237e8a5c5376b65a709824802f?s=80\u0026d=identicon',
    web_url: 'http://127.0.0.1:3001/vsm-user-3-1589776313',
    access_level: 30,
    expires_at: null,
  },
  {
    id: 33,
    name: 'VSM User4',
    username: 'vsm-user-4-1589776313',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/ab506dc600d1a941e4d77d5ceeeba73f?s=80\u0026d=identicon',
    web_url: 'http://127.0.0.1:3001/vsm-user-4-1589776313',
    access_level: 30,
    expires_at: null,
  },
];

export const filterLabels = [
  { id: 194, title: 'Afterfunc-Phureforge-781', color: '#990000', text_color: '#FFFFFF' },
  { id: 10, title: 'Afternix', color: '#16ecf2', text_color: '#FFFFFF' },
  { id: 176, title: 'Panasync-Pens-266', color: '#990000', text_color: '#FFFFFF' },
  { id: 79, title: 'Passat', color: '#f1a3d4', text_color: '#333333' },
  { id: 197, title: 'Phast-Onesync-395', color: '#990000', text_color: '#FFFFFF' },
];
