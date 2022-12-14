# frozen_string_literal: true

module EE
  module IssuePolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:read_only, scope: :subject) { @subject.project.namespace.read_only? }

      rule { read_only }.policy do
        prevent :create_issue
        prevent :update_issue
        prevent :read_issue_iid
        prevent :reopen_issue
        prevent :create_design
        prevent :create_note
      end

      rule { can_be_promoted_to_epic }.policy do
        enable :promote_to_epic
      end
    end
  end
end
