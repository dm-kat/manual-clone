# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::CiSecureFileRegistriesResolver do
  it_behaves_like 'a Geo registries resolver', :geo_ci_secure_file_registry
end
