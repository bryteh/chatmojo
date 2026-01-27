const FEATURE_HELP_URLS = {
  agent_bots: 'https://chat.mojosense.co/help/agent-bots',
  agents: 'https://chat.mojosense.co/help/add-agents',
  audit_logs: 'https://chat.mojosense.co/help/audit-logs',
  campaigns: 'https://chat.mojosense.co/help/campaigns',
  canned_responses: 'https://chat.mojosense.co/help/canned-response',
  channel_email: 'https://chat.mojosense.co/help/email',
  channel_facebook: 'https://chat.mojosense.co/help/facebook',
  custom_attributes: 'https://chat.mojosense.co/help/custom-attributes',
  dashboard_apps: 'https://chat.mojosense.co/help/dashboard-apps',
  help_center: 'https://chat.mojosense.co/help/help-center',
  inboxes: 'https://chat.mojosense.co/help/inboxes',
  integrations: 'https://chat.mojosense.co/help/integrations',
  labels: 'https://chat.mojosense.co/help/labels',
  macros: 'https://chat.mojosense.co/help/macros',
  message_reply_to: 'https://chat.mojosense.co/help/reply-to',
  reports: 'https://chat.mojosense.co/help/reports',
  sla: 'https://chat.mojosense.co/help/sla',
  team_management: 'https://chat.mojosense.co/help/add-teams',
  webhook: 'https://chat.mojosense.co/help/webhooks',
  billing: 'https://chat.mojosense.co/pricing',
  saml: 'https://chat.mojosense.co/help/saml',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
