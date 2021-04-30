# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::LearnGitlabMenu do
  let(:project) { build(:project) }
  let(:experiment_enabled) { true }
  let(:context) { Sidebars::Projects::Context.new(current_user: nil, container: project, learn_gitlab_experiment_enabled: experiment_enabled) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.instance_variable_get(:@items)).to be_empty
  end

  describe '#render?' do
    context 'when learn gitlab experiment is enabled' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when learn gitlab experiment is disabled' do
      let(:experiment_enabled) { false }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end

  describe '#has_pill?' do
    context 'when learn gitlab experiment is enabled' do
      it 'returns true' do
        expect(subject.has_pill?).to eq true
      end
    end

    context 'when learn gitlab experiment is disabled' do
      let(:experiment_enabled) { false }

      it 'returns false' do
        expect(subject.has_pill?).to eq false
      end
    end
  end

  describe '#pill_count' do
    before do
      expect_next_instance_of(LearnGitlab::Onboarding) do |onboarding|
        expect(onboarding).to receive(:completed_percentage).and_return(20)
      end
    end

    it 'returns pill count' do
      expect(subject.pill_count).to eq '20%'
    end
  end
end
