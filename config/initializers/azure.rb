# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  require 'azure_storage_client_overrides'

  Azure::Storage::Common::Client.include(AzureStorageClientOverrides::CoreClientOverride)
  Azure::Storage::Blob::BlobService.include(AzureStorageClientOverrides::BlobStorageClientOverride)
end
