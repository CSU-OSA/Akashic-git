module Gitlab
  module Diff
    module FileCollection
      class Base
        attr_reader :project, :diff_options, :diff_view, :diff_refs, :fallback_diff_refs

        delegate :count, :size, :real_size, to: :diff_files

        def self.default_options
          ::Commit.max_diff_options.merge(ignore_whitespace_change: false, no_collapse: false)
        end

        def initialize(diffable, project:, diff_options: nil, diff_refs: nil, fallback_diff_refs: nil)
          diff_options = self.class.default_options.merge(diff_options || {})

          @diffable = diffable
          @diffs = diffable.raw_diffs(diff_options)
          @project = project
          @diff_options = diff_options
          @diff_refs = diff_refs
          @fallback_diff_refs = fallback_diff_refs
        end

        def diff_files
          @diff_files ||= @diffs.decorate! { |diff| decorate_diff!(diff) }
        end

        private

        def decorate_diff!(diff)
          Gitlab::Diff::File.new(diff, repository: project.repository, diff_refs: diff_refs, fallback_diff_refs: fallback_diff_refs)
        end
      end
    end
  end
end
