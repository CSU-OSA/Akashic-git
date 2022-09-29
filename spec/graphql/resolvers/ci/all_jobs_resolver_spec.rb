# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::AllJobsResolver do
  include GraphqlHelpers

  let_it_be(:successful_job) { create(:ci_build, :success, name: 'Job One') }
  let_it_be(:successful_job_two) { create(:ci_build, :success, name: 'Job Two') }
  let_it_be(:failed_job) { create(:ci_build, :failed, name: 'Job Three') }
  let_it_be(:pending_job) { create(:ci_build, :pending, name: 'Job Three') }

  let(:args) { {} }
  let(:current_user) { create(:admin) }

  subject { resolve_jobs(args) }

  describe '#resolve' do
    context 'with authorized user' do
      context 'with statuses argument' do
        let(:args) { { statuses: [Types::Ci::JobStatusEnum.coerce_isolated_input('SUCCESS')] } }

        it { is_expected.to contain_exactly(successful_job, successful_job_two) }
      end

      context 'with multiple statuses' do
        let(:args) do
          { statuses: [Types::Ci::JobStatusEnum.coerce_isolated_input('SUCCESS'),
                       Types::Ci::JobStatusEnum.coerce_isolated_input('FAILED')] }
        end

        it { is_expected.to contain_exactly(successful_job, successful_job_two, failed_job) }
      end

      context 'without statuses argument' do
        it { is_expected.to contain_exactly(successful_job, successful_job_two, failed_job, pending_job) }
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { nil }

      it { is_expected.to be_empty }
    end
  end

  private

  def resolve_jobs(args = {}, context = { current_user: current_user })
    resolve(described_class, args: args, ctx: context)
  end
end
