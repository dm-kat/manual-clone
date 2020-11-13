# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class ReleaseAssetsInputType < BaseInputObject
    graphql_name 'ReleaseAssetsInput'
    description 'Fields that are available when modifying release assets'

    argument :links, [Types::ReleaseAssetLinkInputType],
             required: false,
             description: 'A list of asset links to associate to the release'
  end
end
