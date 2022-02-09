# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIntegrationsEnableSslVerification, schema: 20220209121435 do
  let(:migration) { described_class.new }
  let(:integrations) { table(:integrations) }

  before do
    integrations.create!(id: 1, type: 'BambooService') # unaffected integration
    integrations.create!(id: 2, type: 'DroneCiService') # no properties
    integrations.create!(id: 3, type: 'DroneCiService', properties: {}.to_json) # no URL
    integrations.create!(id: 4, type: 'DroneCiService', properties: { 'drone_url' => '' }.to_json) # blank URL
    integrations.create!(id: 5, type: 'DroneCiService', properties: { 'drone_url' => 'https://example.com:foo' }.to_json) # invalid URL
    integrations.create!(id: 6, type: 'DroneCiService', properties: { 'drone_url' => 'https://example.com' }.to_json) # unknown URL
    integrations.create!(id: 7, type: 'DroneCiService', properties: { 'drone_url' => 'http://cloud.drone.io' }.to_json) # no HTTPS
    integrations.create!(id: 8, type: 'DroneCiService', properties: { 'drone_url' => 'https://cloud.drone.io' }.to_json) # known URL
    integrations.create!(id: 9, type: 'TeamcityService', properties: { 'teamcity_url' => 'https://example.com' }.to_json) # unknown URL
    integrations.create!(id: 10, type: 'TeamcityService', properties: { 'teamcity_url' => 'https://foo.bar.teamcity.com' }.to_json) # unknown URL
    integrations.create!(id: 11, type: 'TeamcityService', properties: { 'teamcity_url' => 'https://teamcity.com' }.to_json) # unknown URL
    integrations.create!(id: 12, type: 'TeamcityService', properties: { 'teamcity_url' => 'https://customer.teamcity.com' }.to_json) # known URL
  end

  def properties(id)
    properties = integrations.find(id).properties
    Gitlab::Json.parse(properties) if properties
  end

  it 'enables SSL verification for known-good hostnames', :aggregate_failures do
    migration.perform(1, 12)

    # BambooService
    expect(properties(1)).to be_nil

    # DroneCiService
    expect(properties(2)).to be_nil
    expect(properties(3)).not_to include('enable_ssl_verification')
    expect(properties(4)).not_to include('enable_ssl_verification')
    expect(properties(5)).not_to include('enable_ssl_verification')
    expect(properties(6)).not_to include('enable_ssl_verification')
    expect(properties(7)).not_to include('enable_ssl_verification')
    expect(properties(8)).to include('enable_ssl_verification' => true)

    # TeamcityService
    expect(properties(9)).not_to include('enable_ssl_verification')
    expect(properties(10)).not_to include('enable_ssl_verification')
    expect(properties(11)).not_to include('enable_ssl_verification')
    expect(properties(12)).to include('enable_ssl_verification' => true)
  end

  it 'only updates records within the given ID range', :aggregate_failures do
    migration.perform(1, 8)

    expect(properties(8)).to include('enable_ssl_verification' => true)
    expect(properties(12)).not_to include('enable_ssl_verification')
  end

  it 'marks the job as succeeded' do
    expect(Gitlab::Database::BackgroundMigrationJob).to receive(:mark_all_as_succeeded)
      .with('BackfillIntegrationsEnableSslVerification', [1, 10])

    migration.perform(1, 10)
  end
end
