# frozen_string_literal: true

class Experiment < ApplicationRecord
  has_many :experiment_subjects, inverse_of: :experiment

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }

  def self.add_subject(name, variant:, subject:)
    by_name(name).record_subject_and_variant!(subject, variant)
  end

  def self.by_name(name)
    find_or_create_by!(name: name)
  end

  def record_conversion_event_for_subject(subject, context = {})
    raise 'Incompatible subject provided!' unless ExperimentSubject.valid_subject?(subject)

    attr_name = subject.class.table_name.singularize.to_sym
    experiment_subject = experiment_subjects.find_by(attr_name => subject)
    return unless experiment_subject

    experiment_subject.update!(converted_at: Time.current, context: merged_context(experiment_subject, context))
  end

  def record_subject_and_variant!(subject, variant)
    raise 'Incompatible subject provided!' unless ExperimentSubject.valid_subject?(subject)

    attr_name = subject.class.table_name.singularize.to_sym
    experiment_subject = experiment_subjects.find_or_initialize_by(attr_name => subject)
    experiment_subject.assign_attributes(variant: variant)
    # We only call save when necessary because this causes the request to stick to the primary DB
    # even when the save is a no-op
    # https://gitlab.com/gitlab-org/gitlab/-/issues/324649
    experiment_subject.save! if experiment_subject.changed?

    experiment_subject
  end

  private

  def merged_context(experiment_subject, new_context)
    experiment_subject.context.deep_merge(new_context.deep_stringify_keys)
  end
end
