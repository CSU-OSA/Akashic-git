# frozen_string_literal: true

module Iterations
  class Cadence < ApplicationRecord
    include Gitlab::SQL::Pattern
    include EachBatch

    self.table_name = 'iterations_cadences'

    ITERATIONS_AUTOMATION_FIELDS = [:start_date, :duration_in_weeks, :iterations_in_advance].freeze

    belongs_to :group
    has_many :iterations, foreign_key: :iterations_cadence_id, inverse_of: :iterations_cadence

    validates :title, presence: true
    validates :start_date, presence: true, if: :automatic?
    validates :group_id, presence: true
    validates :duration_in_weeks, inclusion: { in: 0..4 }, allow_nil: true
    validates :duration_in_weeks, presence: true, if: :automatic?
    validates :iterations_in_advance, inclusion: { in: 0..10 }, allow_nil: true
    validates :iterations_in_advance, presence: true, if: :automatic?
    validates :active, inclusion: [true, false]
    validates :automatic, inclusion: [true, false]
    validates :description, length: { maximum: 5000 }

    validate :cadence_has_not_started, on: :update, if: -> { automatic? && start_date_changed? }
    validate :first_iteration_has_not_started, on: :update, if: -> { converted_to_automatic? && start_date_changed? }
    validate :cadence_is_automatic

    before_update :set_to_first_start_date, if: -> { converted_to_automatic? }

    after_commit :ensure_iterations_in_advance, on: [:create, :update], if: :changed_iterations_automation_fields?

    scope :with_groups, -> (group_ids) { where(group_id: group_ids) }
    scope :with_duration, -> (duration) { where(duration_in_weeks: duration) }
    scope :is_automatic, -> (automatic) { where(automatic: automatic) }
    scope :is_active, -> (active) { where(active: active) }
    scope :ordered_by_title, -> { order(:title) }
    scope :for_automated_iterations, -> do
      is_automatic(true)
        .where('duration_in_weeks > 0')
        .where("DATE ((COALESCE(iterations_cadences.last_run_date, DATE('01-01-1970')) + iterations_cadences.duration_in_weeks * INTERVAL '1 week')) <= CURRENT_DATE")
    end

    class << self
      def search_title(query)
        fuzzy_search(query, [::Resolvers::IterationsResolver::DEFAULT_IN_FIELD], use_minimum_char_limit: contains_digit?(query))
      end

      private

      def contains_digit?(query)
        !(query =~ / \d+ /).nil?
      end
    end

    def next_open_iteration(date)
      return unless date

      iterations.without_state_enum(:closed).where('start_date >= ?', date).order(start_date: :asc).first
    end

    def can_be_automated?
      active? && automatic? && duration_in_weeks.to_i > 0 && iterations_in_advance.to_i > 0
    end

    def can_roll_over?
      active? && automatic? && roll_over?
    end

    def duration_in_days
      duration_in_weeks * 7
    end

    def ensure_iterations_in_advance
      ::Iterations::Cadences::CreateIterationsWorker.perform_async(self.id) if self.can_be_automated?
    end

    def changed_iterations_automation_fields?
      (previous_changes.keys.map(&:to_sym) & ITERATIONS_AUTOMATION_FIELDS).present?
    end

    def cadence_has_not_started
      if has_started?
        errors.add(:base, _('You cannot change the start date after the cadence has started. Please create a new cadence.'))
      end
    end

    def first_iteration_has_not_started
      return if iterations.empty?

      if first_iteration_start_date <= Date.current
        errors.add(:base, _('You cannot change the start date because the first iteration has already started on %{start_date}.') % { start_date: first_iteration_start_date.to_s })
      end
    end

    def update_iteration_sequences
      connection.execute <<~SQL
        UPDATE sprints SET sequence=t.row_number
        FROM (
          SELECT id, row_number() OVER (ORDER BY start_date) FROM sprints
          WHERE iterations_cadence_id = #{id}
        ) as t
        WHERE t.id=sprints.id AND (sprints.sequence IS DISTINCT FROM t.row_number)
      SQL
    end

    # The method returns the date on which the next iteration needs to start
    # and the number of iterations needed to be scheduled starting from the date.
    #
    # Example. A cadence is created with a start date that's in the past.
    #   The first iteration needs to start on the cadence start date.
    #   We then need to create a certain number of iterations that follow the first iteration back to back:
    #     - Some number of past iterations (these are effectively backfilled)
    #     - A current iteration
    #     - Some number of upcoming iterations following 'iterations_in_advance'
    #
    # If a cadence already has iterations, it takes more effort to figure out
    # when the next iteration needs to be starting. Please see the specs for scenarios.
    def next_schedule_date_and_count
      new_start_date = if iterations.empty?
                         start_date
                       else
                         latest_iteration.due_date.next_occurring(start_weekday)
                       end

      [new_start_date, schedule_count(new_start_date)]
    end

    # The method returns the date on which the first upcoming iteration must start.
    # This method is used when a cadence changes its settings and
    # the dates of existing upcoming iterations need to be re-aligned based on the new cadence settings.
    def next_open_iteration_start_date
      if open_iterations.any?
        open_iterations.first.due_date.next_occurring(start_weekday)
      elsif past_iterations.any?
        # Find the start date for the nearest open iteration
        # as if iterations had been scheduled continously from the most recent past iteration.
        open_start_date = past_iterations.last.due_date.next_occurring(start_weekday)
        open_due_date = open_start_date + duration_in_days - 1

        if open_due_date < Date.current
          intermediate_iterations = ((Date.current - open_start_date) / duration_in_days).floor
          hypothetical_last_due_date = open_start_date + intermediate_iterations * duration_in_days - 1

          open_start_date = hypothetical_last_due_date.next_occurring(start_weekday)
        end

        open_start_date
      else
        start_date
      end
    end

    private

    def schedule_count(new_start_date)
      if current_iteration_start_date?(new_start_date)
        1 + iterations_in_advance
      elsif closed_iteration_start_date?(new_start_date)
        backfill_iterations = ((Date.current - new_start_date) / duration_in_days).floor

        backfill_iterations + 1 + iterations_in_advance
      else
        if start_date == new_start_date
          iterations_in_advance
        else
          prev_open_due_date = open_iterations.any? ? open_iterations.first.due_date : Date.current
          future_count = ((new_start_date - prev_open_due_date - 1) / duration_in_days).floor

          # Take a max b/c iterations are never deleted.
          [0, iterations_in_advance - future_count].max
        end
      end
    end

    def latest_iteration
      iterations.due_date_order_asc.last
    end

    def past_iterations
      iterations.due_date_order_asc.due_date_passed
    end

    def open_iterations
      iterations.due_date_order_asc.start_date_passed
    end

    def current_iteration_start_date?(start_date)
      start_date <= Date.current && compute_due_date(start_date) >= Date.current
    end

    def closed_iteration_start_date?(start_date)
      compute_due_date(start_date) < Date.current
    end

    def compute_due_date(start_date)
      start_date + duration_in_days - 1
    end

    def start_weekday
      Date::DAYS_INTO_WEEK.key(start_date.wday)
    end

    def has_started?
      start_date_was <= Date.current
    end

    def set_to_first_start_date
      self.start_date = first_iteration_start_date unless iterations.empty?
    end

    def first_iteration_start_date
      iterations.first.start_date
    end

    def converted_to_automatic?
      automatic_changed? && automatic?
    end

    def cadence_is_automatic
      return unless changes.key?(:automatic)

      unless automatic?
        errors.add(:base, _('Manual iteration cadences are deprecated. Only automatic iteration cadences are allowed.'))
      end
    end
  end
end
