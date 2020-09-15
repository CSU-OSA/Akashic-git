# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::Incidents::UpdateSeverityService do
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    let(:severity) { 'low' }

    subject(:update_severity) { described_class.new(issuable, user, severity).execute }

    context 'when issuable not an incident' do
      %i(issue merge_request).each do |issuable_type|
        let(:issuable) { build_stubbed(issuable_type) }

        it { is_expected.to be_nil }

        it 'does not set severity' do
          expect { subject }.not_to change(IssuableSeverity, :count)
        end
      end
    end

    context 'when issuable is an incident' do
      let!(:issuable) { create(:incident) }

      context 'when issuable does not have issuable severity yet' do
        it 'creates new record' do
          expect { update_severity }.to change { IssuableSeverity.where(issue: issuable).count }.to(1)
        end

        it 'sets severity to specified value' do
          expect { update_severity }.to change { issuable.severity }.to('low')
        end
      end

      context 'when issuable has an issuable severity' do
        let!(:issuable_severity) { create(:issuable_severity, issue: issuable, severity: 'medium') }

        it 'does not create new record' do
          expect { update_severity }.not_to change(IssuableSeverity, :count)
        end

        it 'updates existing issuable severity' do
          expect { update_severity }.to change { issuable_severity.severity }.to(severity)
        end
      end

      context 'when severity value is unsupported' do
        let(:severity) { 'unsupported-severity' }

        it 'sets the severity to default value' do
          update_severity

          expect(issuable.issuable_severity.severity).to eq(IssuableSeverity::DEFAULT)
        end
      end
    end
  end
end
