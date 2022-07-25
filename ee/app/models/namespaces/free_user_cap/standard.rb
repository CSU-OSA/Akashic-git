# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class Standard
      def initialize(root_namespace)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def over_limit?
        return false unless enforce_cap?

        users_count > FREE_USER_LIMIT
      end

      def reached_limit?
        return false unless enforce_cap?

        users_count >= FREE_USER_LIMIT
      end

      def enforce_cap?
        return false unless enforceable_subscription?

        feature_enabled?
      end

      def remaining_seats
        [FREE_USER_LIMIT - users_count, 0].max
      end

      def feature_enabled?
        ::Feature.enabled?(:free_user_cap, root_namespace)
      end

      private

      attr_reader :root_namespace

      def users_count
        root_namespace.free_plan_members_count || 0
      end

      def enforceable_subscription?
        ::Gitlab::CurrentSettings.should_check_namespace_plan? && root_namespace.has_free_or_no_subscription?
      end
    end
  end
end

Namespaces::FreeUserCap::Standard.prepend_mod
