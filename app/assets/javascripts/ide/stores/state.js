export default () => ({
  currentProjectId: '',
  currentBranchId: '',
  currentMergeRequestId: '',
  changedFiles: [],
  endpoints: {},
  lastCommitMsg: '',
  lastCommitPath: '',
  loading: false,
  openFiles: [],
  parentTreeUrl: '',
  trees: {},
  projects: {},
  leftPanelCollapsed: false,
  rightPanelCollapsed: false,
  panelResizing: false,
  entries: {},
  viewer: 'editor',
  delayViewerUpdated: false,
});
