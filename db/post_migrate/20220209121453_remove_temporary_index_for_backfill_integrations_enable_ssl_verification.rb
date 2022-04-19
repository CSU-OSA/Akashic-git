# frozen_string_literal: true

class RemoveTemporaryIndexForBackfillIntegrationsEnableSslVerification < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_integrations_on_id_where_type_droneci_or_teamcity'
  INDEX_CONDITION = "type IN ('DroneCiService', 'TeamcityService')"

  def up
    # this index was used in 20220209121435_backfill_integrations_enable_ssl_verification
    remove_concurrent_index_by_name :integrations, INDEX_NAME
  end

  def down
    add_concurrent_index :integrations, :id, where: INDEX_CONDITION, name: INDEX_NAME
  end
end
