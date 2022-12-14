# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Exists do
  describe '#satisfied_by?' do
    shared_examples 'an exists rule with a context' do
      it_behaves_like 'a glob matching rule' do
        let(:project) { create(:project, :custom_repo, files: files) }
      end

      context 'after pattern comparision limit is reached' do
        let(:globs) { ['*definitely_not_a_matching_glob*'] }
        let(:project) { create(:project, :repository) }

        before do
          stub_const('Gitlab::Ci::Build::Rules::Rule::Clause::Exists::MAX_PATTERN_COMPARISONS', 2)
          expect(File).to receive(:fnmatch?).twice.and_call_original
        end

        it { is_expected.to be_truthy }
      end
    end

    subject(:satisfied_by?) { described_class.new(globs).satisfied_by?(nil, context) }

    context 'when context is Build::Context::Build' do
      it_behaves_like 'an exists rule with a context' do
        let(:pipeline) { build(:ci_pipeline, project: project, sha: project.repository.commit.sha) }
        let(:context) { Gitlab::Ci::Build::Context::Build.new(pipeline, sha: project.repository.commit.sha) }
      end
    end

    context 'when context is Build::Context::Global' do
      it_behaves_like 'an exists rule with a context' do
        let(:pipeline) { build(:ci_pipeline, project: project, sha: project.repository.commit.sha) }
        let(:context) { Gitlab::Ci::Build::Context::Global.new(pipeline, yaml_variables: {}) }
      end
    end

    context 'when context is Config::External::Context' do
      let(:context) { Gitlab::Ci::Config::External::Context.new(project: project, sha: sha) }

      it_behaves_like 'an exists rule with a context' do
        let(:sha) { project.repository.commit.sha }
      end

      context 'when context has no project' do
        let(:globs) { ['Dockerfile'] }
        let(:project) {}
        let(:sha) { 'abc1234' }

        it { is_expected.to eq(false) }
      end
    end
  end
end
