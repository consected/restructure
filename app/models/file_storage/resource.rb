class FileStorage::Resource < UserBase
  include UserHandler
  self.table_name = 'file_storage_resources'
end
