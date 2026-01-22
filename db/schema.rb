# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_01_22_205347) do
  create_schema "curator"

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_enum :metastreams_descriptives_digital_origin, [
    "born_digital",
    "reformatted_digital",
    "digitized_microfilm",
    "digitized_other_analog",
  ], force: :cascade

  create_enum :metastreams_workflow_processing_state, [
    "initialized",
    "derivatives",
    "complete",
  ], force: :cascade

  create_enum :metastreams_workflow_publishing_state, [
    "draft",
    "review",
    "published",
  ], force: :cascade

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_curator.active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_curator.active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "collections", force: :cascade do |t|
    t.string "ark_id", null: false
    t.bigint "institution_id", null: false
    t.string "name", null: false
    t.text "abstract", default: ""
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ark_id"], name: "index_curator.collections_on_ark_id", unique: true
    t.index ["institution_id"], name: "index_curator.collections_on_institution_id"
  end

  create_table "controlled_terms_authorities", force: :cascade do |t|
    t.string "name", null: false
    t.string "code"
    t.string "base_url"
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["base_url", "code"], name: "unique_idx_ctrl_term_auth_on_base_url", unique: true, where: "((base_url IS NOT NULL) AND ((base_url)::text <> ''::text) AND (code IS NOT NULL) AND ((code)::text <> ''::text))"
    t.index ["code"], name: "unique_idx_ctrl_term_auth_on_code", unique: true, where: "((code IS NOT NULL) AND ((code)::text <> ''::text))"
  end

  create_table "controlled_terms_nomenclatures", force: :cascade do |t|
    t.bigint "authority_id"
    t.jsonb "term_data", default: "{}"
    t.string "type", null: false
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index "(((term_data ->> 'basic'::text))::boolean)", name: "index_ctl_terms_basic_genre_jsonb_field", where: "((type)::text = 'Curator::ControlledTerms::Genre'::text)"
    t.index "((term_data ->> 'id_from_auth'::text))", name: "index_ctl_terms_nom_id_from_auth_jsonb_field"
    t.index ["authority_id"], name: "index_curator.controlled_terms_nomenclatures_on_authority_id"
    t.index ["term_data"], name: "index_ctl_terms_nomenclatures_on_term_data_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
    t.index ["term_data"], name: "index_curator.controlled_terms_nomenclatures_on_term_data", using: :gin
    t.index ["type"], name: "index_curator.controlled_terms_nomenclatures_on_type"
  end

  create_table "digital_objects", force: :cascade do |t|
    t.string "ark_id", null: false
    t.bigint "admin_set_id", null: false
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "archived_at", precision: nil
    t.bigint "contained_by_id"
    t.index ["admin_set_id"], name: "index_curator.digital_objects_on_admin_set_id"
    t.index ["archived_at"], name: "index_curator.digital_objects_on_archived_at", where: "(archived_at IS NULL)"
    t.index ["ark_id"], name: "index_curator.digital_objects_on_ark_id", unique: true
    t.index ["contained_by_id", "id"], name: "unique_idx_digital_objects_on_contained_by_and_id", unique: true, where: "(contained_by_id IS NOT NULL)"
    t.index ["contained_by_id"], name: "idx_digital_objects_on_contained_by"
  end

  create_table "filestreams_file_sets", force: :cascade do |t|
    t.string "ark_id", null: false
    t.string "file_set_type", null: false
    t.string "file_name_base", null: false
    t.integer "position", null: false
    t.jsonb "pagination", default: {}
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "file_set_of_id", null: false
    t.index ["ark_id"], name: "index_curator.filestreams_file_sets_on_ark_id", unique: true
    t.index ["file_set_of_id"], name: "index_fstream_file_set_on_file_set_of_id"
    t.index ["file_set_type"], name: "index_curator.filestreams_file_sets_on_file_set_type"
    t.index ["pagination"], name: "index_curator.filestreams_file_sets_on_pagination", opclass: :jsonb_path_ops, using: :gin
    t.index ["position"], name: "index_curator.filestreams_file_sets_on_position"
  end

  create_table "institutions", force: :cascade do |t|
    t.bigint "location_id"
    t.string "ark_id", null: false
    t.string "name", null: false
    t.string "url"
    t.text "abstract", default: ""
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ark_id"], name: "index_curator.institutions_on_ark_id", unique: true
    t.index ["location_id"], name: "index_inst_on_geo_location_nom"
  end

  create_table "mappings_collection_members", force: :cascade do |t|
    t.bigint "digital_object_id", null: false
    t.bigint "collection_id", null: false
    t.index ["collection_id"], name: "index_mapping_col_members_on_collection"
    t.index ["digital_object_id", "collection_id"], name: "unique_idx_mapping_col_members_on_digital_obj_and_col", unique: true
    t.index ["digital_object_id"], name: "index_mapping_col_members_on_digital_object"
  end

  create_table "mappings_desc_host_collections", force: :cascade do |t|
    t.bigint "host_collection_id", null: false
    t.bigint "descriptive_id", null: false
    t.index ["descriptive_id", "host_collection_id"], name: "unique_idx_desc_mappping_of_col_on_desc_and_host_col", unique: true
    t.index ["descriptive_id"], name: "index_desc_mapping_host_col_on_desc"
    t.index ["host_collection_id"], name: "index_desc_mapping_host_col_on_host_col"
  end

  create_table "mappings_desc_name_roles", force: :cascade do |t|
    t.bigint "descriptive_id", null: false
    t.bigint "name_id", null: false
    t.bigint "role_id", null: false
    t.index ["descriptive_id", "name_id", "role_id"], name: "unique_idx_on_meta_desc_name_role_on_desc_name_role", unique: true
    t.index ["descriptive_id"], name: "index_curator.mappings_desc_name_roles_on_descriptive_id"
    t.index ["name_id"], name: "index_curator.mappings_desc_name_roles_on_name_id"
    t.index ["role_id"], name: "index_curator.mappings_desc_name_roles_on_role_id"
  end

  create_table "mappings_desc_terms", force: :cascade do |t|
    t.bigint "descriptive_id", null: false
    t.bigint "mapped_term_id", null: false
    t.index ["descriptive_id"], name: "index_curator.mappings_desc_terms_on_descriptive_id"
    t.index ["mapped_term_id", "descriptive_id"], name: "unique_idx_desc_map_on_mappable_poly_and_descriptive", unique: true
    t.index ["mapped_term_id"], name: "index_meta_desc_map_on_nomencaluture"
  end

  create_table "mappings_exemplary_images", force: :cascade do |t|
    t.string "exemplary_object_type", null: false
    t.bigint "exemplary_object_id", null: false
    t.bigint "exemplary_file_set_id", null: false
    t.index ["exemplary_file_set_id", "exemplary_object_id", "exemplary_object_type"], name: "uniq_idx_map_exemp_img_on_exemp_obj_poly_and_exemp_fset", unique: true
    t.index ["exemplary_file_set_id"], name: "idx_map_exemp_on_exemp_file_set"
    t.index ["exemplary_object_type", "exemplary_object_id"], name: "unique_idx_map_exemp_img_on_exemp_obj_poly", unique: true
  end

  create_table "mappings_file_set_members", force: :cascade do |t|
    t.bigint "digital_object_id", null: false
    t.bigint "file_set_id", null: false
    t.index ["digital_object_id", "file_set_id"], name: "unique_idx_fset_mem_on_digital_obj_and_fset", unique: true
    t.index ["digital_object_id"], name: "index_mapping_fset_members_on_digital_object"
    t.index ["file_set_id"], name: "idx_fset_member_on_fset_member"
  end

  create_table "mappings_host_collections", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "institution_id", null: false
    t.index ["institution_id"], name: "index_curator.mappings_host_collections_on_institution_id"
    t.index ["name", "institution_id"], name: "unique_idx_map_host_col_col_and_and_name", unique: true
  end

  create_table "metastreams_administratives", force: :cascade do |t|
    t.string "administratable_type", null: false
    t.bigint "administratable_id", null: false
    t.string "oai_header_id"
    t.integer "description_standard"
    t.integer "hosting_status", default: 0
    t.boolean "harvestable", default: true
    t.string "flagged"
    t.string "destination_site", default: ["commonwealth"], array: true
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["administratable_type", "administratable_id"], name: "unique_idx_meta_admin_on_metastreamable_poly", unique: true
    t.index ["description_standard"], name: "idx_administrative_on_not_null_desc_standard", where: "(description_standard IS NOT NULL)"
    t.index ["destination_site"], name: "index_curator.metastreams_administratives_on_destination_site", using: :gin
    t.index ["harvestable"], name: "index_curator.metastreams_administratives_on_harvestable"
    t.index ["hosting_status"], name: "index_curator.metastreams_administratives_on_hosting_status"
    t.index ["oai_header_id"], name: "index_curator.metastreams_administratives_on_oai_header_id", unique: true
  end

  create_table "metastreams_descriptives", force: :cascade do |t|
    t.bigint "physical_location_id", null: false
    t.bigint "license_id", null: false
    t.bigint "rights_statement_id"
    t.jsonb "identifier_json", default: {}
    t.jsonb "title", default: {}
    t.jsonb "date", default: {}
    t.jsonb "note_json", default: {}
    t.jsonb "subject_other", default: {}
    t.jsonb "related", default: {}
    t.jsonb "cartographic", default: {}
    t.jsonb "publication", default: {}
    t.enum "digital_origin", default: "reformatted_digital", enum_type: "metastreams_descriptives_digital_origin"
    t.integer "text_direction"
    t.boolean "resource_type_manuscript", default: false
    t.string "origin_event"
    t.string "place_of_publication"
    t.string "publisher"
    t.string "issuance"
    t.string "frequency"
    t.string "extent"
    t.string "physical_location_department"
    t.string "physical_location_shelf_locator"
    t.string "series"
    t.string "subseries"
    t.string "subsubseries"
    t.string "rights"
    t.string "access_restrictions"
    t.string "toc_url"
    t.text "toc", default: ""
    t.text "abstract", default: ""
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "digital_object_id", null: false
    t.index ["cartographic"], name: "index_curator.metastreams_descriptives_on_cartographic", opclass: :jsonb_path_ops, using: :gin
    t.index ["date"], name: "index_curator.metastreams_descriptives_on_date", opclass: :jsonb_path_ops, using: :gin
    t.index ["digital_object_id"], name: "unique_idx_meta_desc_on_digital_object", unique: true
    t.index ["identifier_json"], name: "index_curator.metastreams_descriptives_on_identifier_json", opclass: :jsonb_path_ops, using: :gin
    t.index ["license_id"], name: "index_curator.metastreams_descriptives_on_license_id"
    t.index ["note_json"], name: "index_curator.metastreams_descriptives_on_note_json", opclass: :jsonb_path_ops, using: :gin
    t.index ["physical_location_id"], name: "index_curator.metastreams_descriptives_on_physical_location_id"
    t.index ["publication"], name: "index_curator.metastreams_descriptives_on_publication", opclass: :jsonb_path_ops, using: :gin
    t.index ["related"], name: "index_curator.metastreams_descriptives_on_related", opclass: :jsonb_path_ops, using: :gin
    t.index ["rights_statement_id"], name: "index_curator.metastreams_descriptives_on_rights_statement_id"
    t.index ["subject_other"], name: "index_curator.metastreams_descriptives_on_subject_other", opclass: :jsonb_path_ops, using: :gin
    t.index ["title"], name: "index_curator.metastreams_descriptives_on_title", opclass: :jsonb_path_ops, using: :gin
  end

  create_table "metastreams_workflows", force: :cascade do |t|
    t.string "workflowable_type", null: false
    t.bigint "workflowable_id", null: false
    t.enum "publishing_state", enum_type: "metastreams_workflow_publishing_state"
    t.enum "processing_state", enum_type: "metastreams_workflow_processing_state"
    t.string "ingest_origin", null: false
    t.integer "lock_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["processing_state"], name: "idx_meta_workflow_on_processing_state"
    t.index ["publishing_state"], name: "idx_meta_workflow_on_publsihing_state"
    t.index ["workflowable_type", "workflowable_id"], name: "unique_idx_meta_workflows_on_metastreamable_poly", unique: true
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.string "foreign_type"
    t.index ["foreign_key_name", "foreign_key_id", "foreign_type"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_curator.version_associations_on_version_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.json "object"
    t.string "item_subtype"
    t.json "object_changes"
    t.datetime "created_at", precision: nil
    t.integer "transaction_id"
    t.index ["item_type", "item_id"], name: "index_curator.versions_on_item_type_and_item_id"
    t.index ["transaction_id"], name: "index_curator.versions_on_transaction_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "collections", "institutions"
  add_foreign_key "controlled_terms_nomenclatures", "controlled_terms_authorities", column: "authority_id", on_delete: :nullify
  add_foreign_key "digital_objects", "collections", column: "admin_set_id"
  add_foreign_key "digital_objects", "digital_objects", column: "contained_by_id", on_delete: :nullify
  add_foreign_key "filestreams_file_sets", "digital_objects", column: "file_set_of_id"
  add_foreign_key "institutions", "controlled_terms_nomenclatures", column: "location_id", on_delete: :nullify
  add_foreign_key "mappings_collection_members", "collections"
  add_foreign_key "mappings_collection_members", "digital_objects"
  add_foreign_key "mappings_desc_host_collections", "mappings_host_collections", column: "host_collection_id"
  add_foreign_key "mappings_desc_host_collections", "metastreams_descriptives", column: "descriptive_id"
  add_foreign_key "mappings_desc_name_roles", "controlled_terms_nomenclatures", column: "name_id"
  add_foreign_key "mappings_desc_name_roles", "controlled_terms_nomenclatures", column: "role_id"
  add_foreign_key "mappings_desc_name_roles", "metastreams_descriptives", column: "descriptive_id"
  add_foreign_key "mappings_desc_terms", "controlled_terms_nomenclatures", column: "mapped_term_id"
  add_foreign_key "mappings_desc_terms", "metastreams_descriptives", column: "descriptive_id"
  add_foreign_key "mappings_exemplary_images", "filestreams_file_sets", column: "exemplary_file_set_id"
  add_foreign_key "mappings_file_set_members", "digital_objects"
  add_foreign_key "mappings_file_set_members", "filestreams_file_sets", column: "file_set_id"
  add_foreign_key "mappings_host_collections", "institutions"
  add_foreign_key "metastreams_descriptives", "controlled_terms_nomenclatures", column: "license_id"
  add_foreign_key "metastreams_descriptives", "controlled_terms_nomenclatures", column: "physical_location_id"
  add_foreign_key "metastreams_descriptives", "controlled_terms_nomenclatures", column: "rights_statement_id"
  add_foreign_key "metastreams_descriptives", "digital_objects"
end
