# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::MergeRequestBasic do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:labels) { create_list(:label, 3) }
  let_it_be(:merge_requests) { create_list(:labeled_merge_request, 10, :unique_branches, :with_diffs, labels: labels) }

  let(:scope) { MergeRequest.with_api_entity_associations }

  # This mimics the behavior of the `Grape::Entity` serializer
  def present(obj)
    described_class.new(obj).presented
  end

  describe "#with_api_entity_associations" do
    it "avoids N+1 queries" do
      query = scope.find(merge_request.id)

      control = ActiveRecord::QueryRecorder.new do
        present(query).to_json
      end

      query = scope.all
      batch = ActiveRecord::QueryRecorder.new do
        entities = query.map(&method(:present))

        entities.to_json
      end

      # The current threshold is 3 query per entity maximum.
      expect(batch.count).to be_within(3 * query.count).of(control.count)
    end
  end
end
