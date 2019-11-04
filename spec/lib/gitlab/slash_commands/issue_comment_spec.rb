# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SlashCommands::IssueComment do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let(:user) { issue.author }

  describe '#execute' do
    let(:chat_name) { double(:chat_name, user: user) }
    let(:regex_match) { described_class.match("issue comment #{issue.iid}\nComment body") }

    subject { described_class.new(project, chat_name).execute(regex_match) }

    context 'when the issue exists' do
      context 'when the user does not have permission' do
        let(:chat_name) { double(:chat_name, user: create(:user)) }

        it 'does not allow the user to comment' do
          expect(subject[:response_type]).to be(:ephemeral)
          expect(subject[:text]).to match('not found')
          expect(issue.reload.notes.count).to be_zero
        end
      end

      context 'when the user can comment on the issue' do
        context 'when comment body exists' do
          it 'creates a new comment' do
            expect { subject }.to change { issue.notes.count }.by(1)
          end

          it 'a new comment has a correct body' do
            subject

            expect(issue.notes.last.note).to eq('Comment body')
          end
        end

        context 'when comment body does not exist' do
          let(:regex_match) { described_class.match("issue comment #{issue.iid}") }

          it 'does not create a new comment' do
            expect { subject }.not_to change { issue.notes.count }
          end

          it 'displays the errors' do
            expect(subject[:response_type]).to be(:ephemeral)
            expect(subject[:text]).to match("- Note can't be blank")
          end
        end
      end
    end

    context 'the issue does not exist' do
      let(:regex_match) { described_class.match("issue comment 2343242\nComment body") }

      it 'returns not found' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to match('not found')
      end
    end
  end

  describe '.match' do
    subject(:match) { described_class.match(command) }

    context 'when a command has an issue ID' do
      context 'when command has a comment body' do
        let(:command) { "issue comment 503\nComment body" }

        it 'matches an issue ID' do
          expect(match[:iid]).to eq('503')
        end

        it 'matches an note body' do
          expect(match[:note_body]).to eq('Comment body')
        end
      end
    end

    context 'when a command has a reference prefix for issue ID' do
      let(:command) { "issue comment #503\nComment body" }

      it 'matches an issue ID' do
        expect(match[:iid]).to eq('503')
      end
    end

    context 'when a command does not have an issue ID' do
      let(:command) { 'issue comment' }

      it 'does not match' do
        is_expected.to be_nil
      end
    end
  end

  describe '.allowed?' do
    subject { described_class.allowed?(issue, user) }

    before do
      allow(Ability).to receive(:allowed?).with(user, :create_note, issue).and_return(is_allowed)
    end

    context 'when the user can create a note' do
      let(:is_allowed) { true }

      it { is_expected.to be_truthy }
    end

    context 'when the user cannot create a note' do
      let(:is_allowed) { false }

      it { is_expected.to be_falsey }
    end
  end
end
