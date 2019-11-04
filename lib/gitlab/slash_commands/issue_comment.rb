# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class IssueComment < IssueCommand
      def self.match(text)
        /\Aissue\s+comment\s+#{Issue.reference_prefix}?(?<iid>\d+)\n*(?<note_body>(.|\n)*)/.match(text)
      end

      def self.help_message
        'issue comment <id> *`⇧ Shift`*+*`↵ Enter`* <comment>'
      end

      def self.allowed?(issue, user)
        can?(user, :create_note, issue)
      end

      def execute(match)
        note_body = match[:note_body].to_s.strip
        issue = find_by_iid(match[:iid])

        return not_found unless issue

        note = create_note(issue: issue, note: note_body)

        if note.persisted?
          presenter(note).present
        else
          presenter(note).display_errors
        end
      end

      private

      def not_found
        Gitlab::SlashCommands::Presenters::Access.new.not_found
      end

      def create_note(issue:, note:)
        note_params = { noteable: issue, note: note }

        Notes::CreateService.new(project, current_user, note_params).execute
      end

      def presenter(note)
        Gitlab::SlashCommands::Presenters::IssueComment.new(note)
      end
    end
  end
end
