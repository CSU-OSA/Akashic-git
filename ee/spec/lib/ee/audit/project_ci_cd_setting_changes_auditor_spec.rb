# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Audit::ProjectCiCdSettingChangesAuditor do
  using RSpec::Parameterized::TableSyntax
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:ci_cd_settings) { project.ci_cd_settings }
    let_it_be(:project_ci_cd_setting_changes_auditor) { described_class.new(user, ci_cd_settings, project) }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    context 'when auditable boolean column is changed' do
      columns = %w[merge_trains_enabled merge_pipelines_enabled]
      columns.each do |column|
        context 'when column changes from boolean' do
          where(:prev_value, :new_value) do
            true  | false
            false | true
          end

          before do
            project.ci_cd_settings.update_attribute(column, prev_value)
          end

          with_them do
            it 'creates an audit event' do
              project.ci_cd_settings.update_attribute(column, new_value)

              expect { project_ci_cd_setting_changes_auditor.execute }.to change { AuditEvent.count }.by(1)
              expect(AuditEvent.last.details).to include({
                                                           change: column,
                                                           from: prev_value,
                                                           to: new_value
                                                         })
            end
          end
        end

        context 'when column changes to false from nil' do
          before do
            project.ci_cd_settings.update_attribute(column, nil)
          end

          it 'does not create an audit event' do
            project.ci_cd_settings.update_attribute(column, false)

            expect { project_ci_cd_setting_changes_auditor.execute }.not_to change { AuditEvent.count }
          end
        end
      end
    end
  end
end
