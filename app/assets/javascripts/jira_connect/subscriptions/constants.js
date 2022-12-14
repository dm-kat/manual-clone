import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const DEFAULT_GROUPS_PER_PAGE = 10;
export const ALERT_LOCALSTORAGE_KEY = 'gitlab_alert';
export const MINIMUM_SEARCH_TERM_LENGTH = 3;

export const ADD_NAMESPACE_MODAL_ID = 'add-namespace-modal';

export const I18N_DEFAULT_SIGN_IN_BUTTON_TEXT = s__('Integrations|Sign in to GitLab');
export const I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE = s__('Integrations|Failed to sign in to GitLab.');
export const I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE = s__(
  'Integrations|Failed to load subscriptions.',
);
export const I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE = s__(
  'Integrations|Namespace successfully linked',
);
export const I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE = s__(
  'Integrations|You should now see GitLab.com activity inside your Jira Cloud issues. %{linkStart}Learn more%{linkEnd}',
);
export const INTEGRATIONS_DOC_LINK = helpPagePath('integration/jira_development_panel', {
  anchor: 'use-the-integration',
});

export const I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE = s__(
  'Integrations|Failed to link namespace. Please try again.',
);

const OAUTH_WINDOW_SIZE = 800;
export const OAUTH_WINDOW_OPTIONS = [
  'resizable=yes',
  'scrollbars=yes',
  'status=yes',
  `width=${OAUTH_WINDOW_SIZE}`,
  `height=${OAUTH_WINDOW_SIZE}`,
  `left=${window.screen.width / 2 - OAUTH_WINDOW_SIZE / 2}`,
  `top=${window.screen.height / 2 - OAUTH_WINDOW_SIZE / 2}`,
].join(',');

export const PKCE_CODE_CHALLENGE_DIGEST_ALGORITHM = {
  long: 'SHA-256',
  short: 'S256',
};
