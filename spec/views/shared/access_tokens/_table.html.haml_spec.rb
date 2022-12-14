# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/access_tokens/_table.html.haml' do
  let(:type) { 'token' }
  let(:type_plural) { 'tokens' }
  let(:empty_message) { nil }
  let(:impersonation) { false }

  let_it_be(:user) { create(:user) }
  let_it_be(:tokens) { [create(:personal_access_token, user: user)] }
  let_it_be(:resource) { false }

  before do
    if resource
      resource.add_maintainer(user)
    end

    # Forcibly removing scopes from one token as it's not possible to do with the current modal on creation
    # But the check exists in the template (it may be there for legacy reasons), so we should test the outcome
    if tokens.size > 1
      tokens[1].scopes = []
    end

    locals = {
      type: type,
      type_plural: type_plural,
      active_tokens: tokens,
      resource: resource,
      impersonation: impersonation,
      revoke_route_helper: ->(token) { 'path/' }
    }

    if empty_message
      locals[:no_active_tokens_message] = empty_message
    end

    render partial: 'shared/access_tokens/table', locals: locals
  end

  context 'if personal' do
    it 'does not show non-personal content', :aggregate_failures do
      expect(rendered).not_to have_content 'To see all the user\'s personal access tokens you must impersonate them first.'
      expect(rendered).not_to have_selector 'th', text: 'Role'
    end
  end

  context 'if impersonation' do
    let(:impersonation) { true }

    it 'shows the impersonation content', :aggregate_failures do
      expect(rendered).to have_content 'To see all the user\'s personal access tokens you must impersonate them first.'

      expect(rendered).not_to have_content 'Personal access tokens are not revoked upon expiration.'
      expect(rendered).not_to have_selector 'th', text: 'Role'
    end
  end

  context 'if resource is project' do
    let_it_be(:resource) { create(:project) }

    it 'shows the project content', :aggregate_failures do
      expect(rendered).to have_selector 'th', text: 'Role'
      expect(rendered).to have_selector 'td', text: 'Maintainer'

      expect(rendered).not_to have_content 'Personal access tokens are not revoked upon expiration.'
      expect(rendered).not_to have_content 'To see all the user\'s personal access tokens you must impersonate them first.'
    end
  end

  context 'if resource is group' do
    let_it_be(:resource) { create(:group) }

    it 'shows the group content', :aggregate_failures do
      expect(rendered).to have_selector 'th', text: 'Role'
      expect(rendered).to have_selector 'td', text: 'Maintainer'

      expect(rendered).not_to have_content 'Personal access tokens are not revoked upon expiration.'
      expect(rendered).not_to have_content 'To see all the user\'s personal access tokens you must impersonate them first.'
    end
  end

  context 'without tokens' do
    let_it_be(:tokens) { [] }

    it 'has the correct content', :aggregate_failures do
      expect(rendered).to have_content 'Active tokens (0)'
      expect(rendered).to have_content 'This user has no active tokens.'
    end

    context 'with a custom empty text' do
      let(:empty_message) { 'Custom empty message' }

      it 'shows the custom empty text' do
        expect(rendered).to have_content empty_message
      end
    end
  end

  context 'with tokens' do
    let_it_be(:tokens) do
      [
        create(:personal_access_token, user: user, name: 'Access token', last_used_at: 4.days.from_now, expires_at: nil, scopes: [:read_api, :read_user]),
        create(:personal_access_token, user: user, expires_at: 1.day.from_now, scopes: [:read_api, :read_user])
      ]
    end

    let_it_be(:expired_token) { build(:personal_access_token, name: "Expired token", expires_at: 2.days.ago).tap { |t| t.save!(validate: false) } }

    it 'has the correct content', :aggregate_failures do
      # Heading content
      expect(rendered).to have_content 'Active tokens (2)'

      # Table headers
      expect(rendered).to have_selector 'th', text: 'Token name'
      expect(rendered).to have_selector 'th', text: 'Scopes'
      expect(rendered).to have_selector 'th', text: 'Created'
      expect(rendered).to have_selector 'th', text: 'Last Used'
      expect(rendered).to have_selector 'th', text: 'Expires'

      # Table contents
      expect(rendered).to have_content 'Access token'
      expect(rendered).not_to have_content 'Expired token'
      expect(rendered).to have_content 'read_api, read_user'
      expect(rendered).to have_content 'no scopes selected'
      expect(rendered).to have_content Time.now.to_date.to_s(:medium)
      expect(rendered).to have_content l(4.days.from_now, format: "%b %d, %Y")

      # Revoke buttons
      expect(rendered).to have_link 'Revoke', href: 'path/', class: 'btn-danger-secondary', count: 1
      expect(rendered).to have_link 'Revoke', href: 'path/', count: 2
    end

    context 'without the last used time' do
      let_it_be(:tokens) { [create(:personal_access_token, user: user, expires_at: 5.days.ago)] }

      it 'shows the last used empty text' do
        expect(rendered).to have_content 'Never'
      end
    end

    context 'without expired at' do
      let_it_be(:tokens) { [create(:personal_access_token, user: user, expires_at: nil, last_used_at: 1.day.ago)] }

      it 'shows the expired at empty text' do
        expect(rendered).to have_content 'Never'
      end
    end
  end
end
