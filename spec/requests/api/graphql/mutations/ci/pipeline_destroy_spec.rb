# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineDestroy' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }

  let(:mutation) do
    variables = {
      id: pipeline.id
    }
    graphql_mutation(:pipeline_destroy, variables,
                     <<-QL
                       errors
                     QL
    )
  end

  it 'returns an error if the user is not allowed to destroy the pipeline' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'destroys a pipeline' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
