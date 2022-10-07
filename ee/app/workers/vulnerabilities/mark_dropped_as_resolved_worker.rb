# frozen_string_literal: true

module Vulnerabilities
  # rubocop:disable Scalability/IdempotentWorker
  class MarkDroppedAsResolvedWorker
    include ApplicationWorker

    data_consistency :delayed

    feature_category :static_application_security_testing

    def perform(project_id, dropped_identifier_ids)
      @project_id = project_id
      @dropped_identifier_ids = dropped_identifier_ids

      dropped_vulnerabilities.each_batch { |batch| resolve_batch(batch) }
    end

    private

    def resolve_batch(vulnerabilities)
      ::Vulnerability.transaction do
        create_state_transitions(vulnerabilities)

        vulnerabilities.update_all(
          resolved_by_id: User.security_bot.id,
          resolved_at: Time.zone.now,
          state: :resolved)
      end
    end

    def dropped_vulnerabilities
      ::Vulnerability
        .with_states(:detected)
        .with_resolution(true)
        .for_projects(@project_id)
        .by_identifier_ids(@dropped_identifier_ids)
    end

    def create_state_transitions(vulnerabilities)
      state_transitions = vulnerabilities.find_each.map do |vulnerability|
        build_state_transition_for(vulnerability)
      end

      Vulnerabilities::StateTransition.bulk_insert!(state_transitions)
    end

    def build_state_transition_for(vulnerability)
      current_time = Time.zone.now

      ::Vulnerabilities::StateTransition.new(
        vulnerability: vulnerability,
        from_state: vulnerability.state,
        to_state: :resolved,
        author_id: User.security_bot.id,
        created_at: current_time,
        updated_at: current_time
      )
    end
  end
  # rubocop:enable Scalability/IdempotentWorker
end
