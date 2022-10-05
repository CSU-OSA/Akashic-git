# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Standard, :saas do
  let_it_be(:namespace, reload: true) { create(:group_with_plan, :private, plan: :free_plan) }

  let(:dashboard_limit_enabled) { true }

  before do
    stub_ee_application_setting(dashboard_limit_enabled: dashboard_limit_enabled)
  end

  shared_context 'with net new namespace' do
    let(:enforcement_date) { Date.today }
    let_it_be(:namespace) do
      travel_to(Date.today + 2.days) do
        create(:group_with_plan, :private, plan: :free_plan)
      end
    end
  end

  describe '#over_limit?' do
    let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit + 1 }

    subject(:over_limit?) { described_class.new(namespace).over_limit? }

    before do
      allow(namespace).to receive(:free_plan_members_count).and_return(free_plan_members_count)
    end

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be false }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be false }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be true }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated' do
          it { is_expected.to be false }
        end
      end
    end

    context 'when :free_user_cap is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'when under the number of free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit - 1 }

        it { is_expected.to be false }
      end

      context 'when at the same number as the free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit }

        it { is_expected.to be false }
      end

      context 'when over the number of free users limit' do
        context 'when it is a free plan' do
          it { is_expected.to be true }

          context 'when the namespace is not a group' do
            let_it_be(:namespace) do
              namespace = create(:user).namespace
              create(:gitlab_subscription, hosted_plan: create(:free_plan), namespace: namespace)
              namespace
            end

            it { is_expected.to be false }
          end

          context 'when the namespace is public' do
            before do
              namespace.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            end

            it { is_expected.to be false }
          end
        end

        context 'when it is a non free plan' do
          let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }

          it { is_expected.to be false }
        end

        context 'when no plan exists' do
          let_it_be(:namespace) { create(:group, :private) }

          it { is_expected.to be true }

          context 'when namespace is public' do
            let_it_be(:namespace) { create(:group, :public) }

            it { is_expected.to be false }
          end
        end

        context 'when dashboard_limit_enabled is false' do
          let(:dashboard_limit_enabled) { false }

          it { is_expected.to be false }
        end
      end

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be false }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be true }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled it honors existing namespace logic' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be true }
          end
        end

        context 'when enforcement date is not populated it honors existing namespace logic' do
          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#reached_limit?' do
    let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit + 1 }

    subject(:reached_limit?) { described_class.new(namespace).reached_limit? }

    before do
      allow(namespace).to receive(:free_plan_members_count).and_return(free_plan_members_count)
    end

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be false }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be true }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be true }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated' do
          it { is_expected.to be false }
        end
      end
    end

    context 'when :free_user_cap is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'when under the number of free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit - 1 }

        it { is_expected.to be false }
      end

      context 'when at the same number as the free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit }

        it { is_expected.to be true }
      end

      context 'when over the number of free users limit' do
        context 'when it is a free plan' do
          it { is_expected.to be true }

          context 'when the namespace is not a group' do
            let_it_be(:namespace) do
              namespace = create(:user).namespace
              create(:gitlab_subscription, hosted_plan: create(:free_plan), namespace: namespace)
              namespace
            end

            it { is_expected.to be false }
          end
        end

        context 'when it is a non free plan' do
          let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }

          it { is_expected.to be false }
        end

        context 'when no plan exists' do
          let_it_be(:namespace) { create(:group, :private) }

          it { is_expected.to be true }

          context 'when namespace is public' do
            let_it_be(:namespace) { create(:group, :public) }

            it { is_expected.to be false }
          end
        end

        context 'when dashboard_limit_enabled is false' do
          let(:dashboard_limit_enabled) { false }

          it { is_expected.to be false }
        end
      end

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be true }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be true }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled it honors existing namespace logic' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be true }
          end
        end

        context 'when enforcement date is not populated it honors existing namespace logic' do
          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#seat_available?' do
    let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit + 1 }
    let_it_be(:user) { create(:user) }

    subject(:seat_available?) { described_class.new(namespace).seat_available?(user) }

    before do
      allow(namespace).to receive(:free_plan_members_count).and_return(free_plan_members_count)
    end

    shared_examples 'user is an already existing member in the namespace' do
      before do
        build(:group_member, :owner, source: namespace, user: user).tap do |record|
          record.save!(validate: false)
        end
      end

      it { is_expected.to be true }
    end

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be true }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be true }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be false }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be false }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be true }
          end
        end

        context 'when enforcement date is not populated' do
          it { is_expected.to be true }
        end
      end
    end

    context 'when :free_user_cap is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'when under the number of free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit - 1 }

        it { is_expected.to be true }
      end

      context 'when at the same number as the free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit }

        it { is_expected.to be false }

        it_behaves_like 'user is an already existing member in the namespace'
      end

      context 'when over the number of free users limit' do
        context 'when it is a free plan' do
          it { is_expected.to be false }

          it_behaves_like 'user is an already existing member in the namespace'

          context 'when the namespace is not a group' do
            let_it_be(:namespace) do
              namespace = create(:user).namespace
              create(:gitlab_subscription, hosted_plan: create(:free_plan), namespace: namespace)
              namespace
            end

            it { is_expected.to be true }
          end
        end

        context 'when it is a non free plan' do
          let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }

          it { is_expected.to be true }
        end

        context 'when no plan exists' do
          let_it_be(:namespace) { create(:group, :private) }

          it { is_expected.to be false }

          context 'when namespace is public' do
            let_it_be(:namespace) { create(:group, :public) }

            it { is_expected.to be true }
          end
        end

        context 'when dashboard_limit_enabled is false' do
          let(:dashboard_limit_enabled) { false }

          it { is_expected.to be true }
        end
      end

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be true }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be false }

              it_behaves_like 'user is an already existing member in the namespace'
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be false }

              it_behaves_like 'user is an already existing member in the namespace'
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled it honors existing namespace logic' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated it honors existing namespace logic' do
          it { is_expected.to be false }
        end
      end
    end
  end

  describe '#users_count' do
    subject { described_class.new(namespace).users_count }

    it { is_expected.to eq(0) }
  end

  describe '#enforce_cap?' do
    subject(:enforce_cap?) { described_class.new(namespace).enforce_cap? }

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be false }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            it { is_expected.to be true }
          end

          context 'when :free_user_cap_new_namespaces is disabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated' do
          it { is_expected.to be false }
        end
      end
    end

    context 'when :free_user_cap is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'when it is a free plan' do
        it { is_expected.to be true }

        context 'when namespace is public' do
          let_it_be(:namespace) { create(:group, :public) }

          it { is_expected.to be false }
        end
      end

      context 'when it is a non free plan' do
        let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }

        it { is_expected.to be false }
      end

      context 'when no plan exists' do
        let_it_be(:namespace) { create(:group, :private) }

        it { is_expected.to be true }

        context 'when namespace is public' do
          let_it_be(:namespace) { create(:group, :public) }

          it { is_expected.to be false }
        end
      end

      context 'when dashboard_limit_enabled is false' do
        let(:dashboard_limit_enabled) { false }

        it { is_expected.to be false }
      end
    end
  end
end
