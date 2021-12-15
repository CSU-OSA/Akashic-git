# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Fuzzing::Coverage::Corpus, type: :model do
  let(:corpus) { create(:corpus) }

  subject { corpus }

  describe 'associations' do
    it { is_expected.to belong_to(:package).class_name('Packages::Package') }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validate' do
    describe 'project_same_as_package_project' do
      let(:package) { create(:generic_package, :with_zip_file) }

      subject(:corpus) { build(:corpus, package: package) }

      it 'raises the error on adding the package of a different project' do
        expect { corpus.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package should belong to the associated project')
      end
    end

    describe 'package_with_package_file' do
      let(:package) { create(:package) }

      subject(:corpus) { build(:corpus, package: package, project: package.project) }

      it 'raises the error on adding the package file with different format' do
        expect { corpus.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package should have an associated package file')
      end
    end

    describe 'validate_file_format' do
      let(:package_file) { create(:package_file) }
      let(:package) { package_file.package }

      subject(:corpus) { build(:corpus, package: package, project: package.project) }

      it 'raises the error on adding the package file with different format' do
        expect { corpus.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package format is not supported')
      end
    end
  end

  describe 'validates' do
    it { is_expected.to validate_uniqueness_of(:package_id) }
  end

  describe 'scopes' do
    describe 'by_project_id' do
      it 'includes the correct records' do
        another_corpus_profile = create(:corpus)

        result = described_class.by_project_id(subject.package.project_id)

        aggregate_failures do
          expect(result).to include(subject)
          expect(result).not_to include(another_corpus_profile)
        end
      end
    end
  end
end
