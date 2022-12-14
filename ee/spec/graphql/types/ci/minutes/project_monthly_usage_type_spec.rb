# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiMinutesProjectMonthlyUsage'] do
  it do
    expect(described_class).to have_graphql_fields(:minutes, :name, :shared_runners_duration)
  end
end
