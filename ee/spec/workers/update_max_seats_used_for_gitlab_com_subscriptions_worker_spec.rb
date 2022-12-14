# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker, :saas do
  describe '#perform' do
    subject { described_class.new }

    let_it_be(:bronze_plan) { create(:bronze_plan) }
    let_it_be(:gitlab_subscription, refind: true) do
      create(:gitlab_subscription, namespace: create(:namespace, :with_namespace_settings), seats: 2)
    end

    let_it_be(:gitlab_subscription_2, refind: true) do
      create(
        :gitlab_subscription,
        namespace: create(:namespace, :with_namespace_settings),
        seats: 11,
        max_seats_used: 11,
        max_seats_used_changed_at: 1.month.ago.to_s(:db)
      )
    end

    let(:db_is_read_only) { false }
    let(:subscription_attrs) { nil }

    before do
      allow(Gitlab::Database).to receive(:read_only?) { db_is_read_only }
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }
    end

    def perform_and_reload
      subject.perform
      gitlab_subscription.reload
      gitlab_subscription_2.reload
    end

    shared_examples 'updates nothing' do
      it 'does not update seat columns' do
        expect do
          perform_and_reload
        end.to not_change(gitlab_subscription, :max_seats_used)
          .and not_change(gitlab_subscription, :seats_in_use)
          .and not_change(gitlab_subscription, :seats_owed)
          .and not_change(gitlab_subscription, :max_seats_used_changed_at)
          .and not_change(gitlab_subscription_2, :max_seats_used)
          .and not_change(gitlab_subscription_2, :seats_in_use)
          .and not_change(gitlab_subscription_2, :seats_owed)
          .and not_change(gitlab_subscription_2, :max_seats_used_changed_at)
      end
    end

    shared_examples 'updates only paid plans' do
      it "persists seat attributes after refresh_seat_attributes! for only paid plans", :freeze_time do
        expect do
          perform_and_reload
        end.to not_change(gitlab_subscription, :max_seats_used)
          .and not_change(gitlab_subscription, :seats_in_use)
          .and not_change(gitlab_subscription, :seats_owed)
          .and not_change(gitlab_subscription, :max_seats_used_changed_at)
          .and change(gitlab_subscription_2, :max_seats_used).from(11).to(14)
          .and change(gitlab_subscription_2, :seats_in_use).from(0).to(13)
          .and change(gitlab_subscription_2, :seats_owed).from(0).to(12)
          .and change(gitlab_subscription_2, :max_seats_used_changed_at).to(be_like_time(Time.current))
      end
    end

    context 'where the DB is read-only' do
      let(:db_is_read_only) { true }

      include_examples 'updates nothing'
    end

    context 'when the DB is not read-only' do
      before do
        gitlab_subscription.update!(subscription_attrs) if subscription_attrs

        allow_next_found_instance_of(GitlabSubscription) do |subscription|
          allow(subscription).to receive(:refresh_seat_attributes!) do
            subscription.max_seats_used = subscription.seats + 3
            subscription.seats_in_use = subscription.seats + 2
            subscription.seats_owed = subscription.seats + 1
          end
        end
      end

      context 'with a free plan' do
        let(:subscription_attrs) { { hosted_plan: nil } }

        include_examples 'updates only paid plans'
      end

      context 'with a trial plan' do
        let(:subscription_attrs) { { hosted_plan: bronze_plan, trial: true } }

        include_examples 'updates only paid plans'
      end

      context 'with a paid plan', :aggregate_failures do
        before do
          gitlab_subscription.update!(hosted_plan: bronze_plan)
          gitlab_subscription_2.update!(hosted_plan: bronze_plan)
        end

        it 'persists seat attributes after refresh_seat_attributes', :freeze_time do
          expect do
            perform_and_reload
          end.to change(gitlab_subscription, :max_seats_used).from(0).to(5)
            .and change(gitlab_subscription, :seats_in_use).from(0).to(4)
            .and change(gitlab_subscription, :seats_owed).from(0).to(3)
            .and change(gitlab_subscription, :max_seats_used_changed_at).from(nil).to(be_like_time(Time.current))
            .and change(gitlab_subscription_2, :max_seats_used).from(11).to(14)
            .and change(gitlab_subscription_2, :seats_in_use).from(0).to(13)
            .and change(gitlab_subscription_2, :seats_owed).from(0).to(12)
            .and change(gitlab_subscription_2, :max_seats_used_changed_at).to(be_like_time(Time.current))
        end
      end
    end

    context 'when the max_seat_used does not increase' do
      before do
        allow_next_found_instance_of(GitlabSubscription) do |subscription|
          allow(subscription).to receive(:refresh_seat_attributes!) do
            subscription.max_seats_used = subscription.max_seats_used
            subscription.seats_in_use = subscription.seats - 1
            subscription.seats_owed = subscription.seats_owed
          end
        end
      end

      it 'does not change the max_seats_used or max_seats_used_changed_at', :freeze_time do
        expect { perform_and_reload }
          .to not_change(gitlab_subscription, :max_seats_used)
          .and not_change(gitlab_subscription, :seats_owed)
          .and not_change(gitlab_subscription, :max_seats_used_changed_at)
          .and change(gitlab_subscription, :seats_in_use).from(0).to(1)
          .and not_change(gitlab_subscription_2, :max_seats_used)
          .and not_change(gitlab_subscription_2, :max_seats_used_changed_at)
          .and not_change(gitlab_subscription_2, :seats_owed)
          .and change(gitlab_subscription_2, :seats_in_use).from(0).to(10)
      end

      context 'when all subscriptions have max_seats_used_changed_at set to nil' do
        # In the Postgres constant table, when all values of a column are `NULL`, the column type is resolved as `text`.
        # For the `max_seats_used_changed_at` column, this will cause an error because `text` is incompatible with
        # `timestamp`. This spec is to ensure this special case is handled correctly.

        before do
          gitlab_subscription_2.update!(max_seats_used_changed_at: nil)
        end

        it 'does not change the max_seats_used_changed_at' do
          expect { perform_and_reload }
            .to not_change(gitlab_subscription, :max_seats_used_changed_at)
            .and not_change(gitlab_subscription_2, :max_seats_used_changed_at)
        end
      end
    end

    context 'when a statement timeout exception is thrown for a subscription' do
      before do
        allow_next_found_instance_of(GitlabSubscription) do |subscription|
          allow(subscription).to receive(:refresh_seat_attributes!) do
            if subscription.id == gitlab_subscription.id
              raise ActiveRecord::QueryCanceled, 'statement timeout'
            else
              subscription.max_seats_used = subscription.seats + 3
              subscription.seats_in_use = subscription.seats + 2
              subscription.seats_owed = subscription.seats + 1
            end
          end
        end
      end

      it 'catches and logs the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(ActiveRecord::QueryCanceled),
          { gitlab_subscription_id: gitlab_subscription.id,
            namespace_id: gitlab_subscription.namespace_id })

        perform_and_reload
      end

      it 'successfully updates remaining subscriptions', :freeze_time do
        expect do
          perform_and_reload
        end.to not_change(gitlab_subscription, :max_seats_used).from(0)
          .and not_change(gitlab_subscription, :seats_in_use).from(0)
          .and not_change(gitlab_subscription, :seats_owed).from(0)
          .and not_change(gitlab_subscription, :max_seats_used_changed_at)
          .and change(gitlab_subscription_2, :max_seats_used).from(11).to(14)
          .and change(gitlab_subscription_2, :seats_in_use).from(0).to(13)
          .and change(gitlab_subscription_2, :seats_owed).from(0).to(12)
          .and change(gitlab_subscription_2, :max_seats_used_changed_at).to(be_like_time(Time.current))
      end
    end
  end

  describe '.last_enqueue_time' do
    it 'returns last_enqueue_time from the cron job instance' do
      time = Time.current
      allow(Sidekiq::Cron::Job).to receive(:find)
        .with('update_max_seats_used_for_gitlab_com_subscriptions_worker')
        .and_return(double(Sidekiq::Cron::Job, last_enqueue_time: time))

      expect(described_class.last_enqueue_time).to eq(time)
    end

    context 'when job is not found' do
      it 'returns nil' do
        allow(Sidekiq::Cron::Job).to receive(:find)
          .with('update_max_seats_used_for_gitlab_com_subscriptions_worker')
          .and_return(nil)

        expect(described_class.last_enqueue_time).to be_nil
      end
    end
  end
end
