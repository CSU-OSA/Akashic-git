# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['EpicConnection'] do
  it 'has the expected fields' do
    expected_fields = %i[edges nodes count pageInfo]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
