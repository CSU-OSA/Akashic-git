# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Issues
        class LazyBlockAggregate < ::Gitlab::Graphql::Aggregations::Issuables::LazyBlockAggregate
          def link_class
            IssueLink
          end
        end
      end
    end
  end
end
