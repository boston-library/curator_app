# frozen_string_literal: true

class ChangePaginationDefaultOnFilestreams < ActiveRecord::Migration[7.2]
  def change
    change_column_default :filestreams_file_sets, :pagination, from: '{}', to: {}
    Curator::Filestreams::FileSet.where("pagination = ?", '{}').update_all(pagination: {})
  end
end
