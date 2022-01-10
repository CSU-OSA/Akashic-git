# frozen_string_literal: true

class RemoveDastSiteProfilesBuildsCiBuildIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_a325505e99'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:dast_site_profiles_builds, :ci_builds, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(:dast_site_profiles_builds, :ci_builds, column: :ci_build_id, on_delete: :cascade, name: CONSTRAINT_NAME)
  end
end
