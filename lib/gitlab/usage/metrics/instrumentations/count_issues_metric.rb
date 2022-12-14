# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountIssuesMetric < DatabaseMetric
          operation :count

          start { Issue.minimum(:id) }
          finish { Issue.maximum(:id) }

          relation { Issue }

          cache_start_and_finish_as :issue
        end
      end
    end
  end
end
