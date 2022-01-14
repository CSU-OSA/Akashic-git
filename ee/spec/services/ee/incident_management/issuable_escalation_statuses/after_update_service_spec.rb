# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::AfterUpdateService do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:escalation_status, reload: true) { create(:incident_management_issuable_escalation_status) }
  let_it_be(:issue, reload: true) { escalation_status.issue }
  let_it_be(:project) { issue.project }
  let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }

  let(:status_event) { :acknowledge }
  let(:policy) { escalation_policy }
  let(:escalations_started_at) { Time.current }
  let(:service) { IncidentManagement::IssuableEscalationStatuses::AfterUpdateService.new(issue, current_user) }

  subject(:result) { service.execute }

  before do
    project.add_developer(current_user)
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  shared_examples 'does not alter the pending escalations' do
    specify do
      update_issue(status_event, policy, escalations_started_at)

      expect(::IncidentManagement::PendingEscalations::IssueCreateWorker).not_to receive(:perform_async)
      expect { result }.not_to change(::IncidentManagement::PendingEscalations::Issue, :count)
    end
  end

  context 'when escalation policies feature is unavailable' do
    before do
      stub_licensed_features(escalation_policies: false)
    end

    it_behaves_like 'does not alter the pending escalations'
  end

  context 'when issue is associated with an alert' do
    let_it_be(:alert) { create(:alert_management_alert, issue: issue, project: project) }

    it_behaves_like 'does not alter the pending escalations'
  end

  context 'resetting pending escalations' do
    using RSpec::Parameterized::TableSyntax

    where(:old_status, :new_status, :had_policy, :has_policy, :should_delete, :should_create) do
      :triggered    | :triggered    | false | false | false | false # status unchanged open
      :resolved     | :resolved     | false | false | false | false # status unchanged closed
      :triggered    | :acknowledged | false | false | false | false # open -> open
      :acknowledged | :resolved     | false | false | false | false # open -> closed
      :resolved     | :triggered    | false | false | false | false # closed -> open
      :resolved     | :ignored      | false | false | false | false # closed -> closed

      :triggered    | :triggered    | true | false | true  | false
      :resolved     | :resolved     | true | false | false | false
      :triggered    | :acknowledged | true | false | true  | false
      :acknowledged | :resolved     | true | false | true  | false
      :resolved     | :triggered    | true | false | false | false
      :resolved     | :ignored      | true | false | false | false

      :triggered    | :triggered    | true | true | false | false
      :resolved     | :resolved     | true | true | false | false
      :triggered    | :acknowledged | true | true | false | false
      :acknowledged | :resolved     | true | true | true  | false
      :resolved     | :triggered    | true | true | false | true
      :resolved     | :ignored      | true | true | false | false

      :triggered    | :triggered    | false | true | false | true # status unchanged
      :resolved     | :triggered    | false | true | false | true # closed -> open
      :acknowledged | :triggered    | false | true | false | true # open -> open
    end

    with_them do
      let(:old_policy) { had_policy ? escalation_policy : nil }
      let(:old_escalations_started_at) { had_policy ? Time.current : nil }
      let(:old_status_event) { escalation_status.status_event_for(old_status) }

      let(:policy) { has_policy ? escalation_policy : nil }
      let(:escalations_started_at) { has_policy ? Time.current : nil }
      let(:status_event) { escalation_status.status_event_for(new_status) }

      before do
        if had_policy && [:acknowledged, :triggered].include?(old_status)
          create(:incident_management_pending_issue_escalation, issue: issue, policy: escalation_policy, project: project)
        end
      end

      it 'deletes or creates pending escalations as required' do
        update_issue(old_status_event, old_policy, old_escalations_started_at)
        update_issue(status_event, policy, escalations_started_at)

        if should_create
          expect(::IncidentManagement::PendingEscalations::IssueCreateWorker).to receive(:perform_async).with(issue.id)
        else
          expect(::IncidentManagement::PendingEscalations::IssueCreateWorker).not_to receive(:perform_async)
        end

        if should_delete
          expect { result }.to change(::IncidentManagement::PendingEscalations::Issue, :count).by(-1)
        else
          expect { result }.not_to change(::IncidentManagement::PendingEscalations::Issue, :count)
        end
      end
    end
  end

  def update_issue(status_event, policy, escalations_started_at)
    issue.update!(
      incident_management_issuable_escalation_status_attributes: {
        status_event: status_event,
        policy: policy,
        escalations_started_at: escalations_started_at
      }
    )
  end
end
