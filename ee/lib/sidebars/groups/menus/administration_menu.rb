# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class AdministrationMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize
        include ::Gitlab::Experiment::Dsl

        override :configure_menu_items
        def configure_menu_items
          return false unless administration_menu_enabled?

          add_item(saml_sso_menu_item)
          add_item(usage_quotas_menu_item)
          add_item(billing_menu_item)

          true
        end

        override :title
        def title
          _('Administration')
        end

        override :sprite_icon
        def sprite_icon
          'admin'
        end

        private

        def administration_menu_enabled?
          ::Feature.enabled?(:group_administration_nav_item, context.group) &&
            context.group.root? &&
            can?(context.current_user, :admin_group, context.group)
        end

        def saml_sso_menu_item
          unless can?(context.current_user, :admin_group_saml, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :saml_sso)
          end

          ::Sidebars::MenuItem.new(
            title: _('SAML SSO'),
            link: group_saml_providers_path(context.group),
            active_routes: { path: 'saml_providers#show' },
            item_id: :saml_sso
          )
        end

        def usage_quotas_menu_item
          unless usage_quotas_enabled?
            return ::Sidebars::NilMenuItem.new(item_id: :usage_quotas)
          end

          ::Sidebars::MenuItem.new(
            title: s_('UsageQuota|Usage Quotas'),
            link: group_usage_quotas_path(context.group),
            active_routes: { path: 'usage_quotas#index' },
            item_id: :usage_quotas
          )
        end

        def usage_quotas_enabled?
          ::License.feature_available?(:usage_quotas) && context.group.root?
        end

        def billing_menu_item
          unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
            return ::Sidebars::NilMenuItem.new(item_id: :billing)
          end

          local_active_routes = { path: 'billings#index' }

          experiment(:billing_in_side_nav, actor: context.current_user, namespace: context.group.root_ancestor, sticky_to: context.current_user) do |e|
            e.control {}
            e.candidate do
              local_active_routes = {
                page: group_billings_path(context.group),
                exclude_page: group_billings_path(context.group, from: :side_nav)
              }
            end
          end

          ::Sidebars::MenuItem.new(
            title: _('Billing'),
            link: group_billings_path(context.group),
            active_routes: local_active_routes,
            item_id: :billing
          )
        end
      end
    end
  end
end
