
Sequel.migration do
  change do
    create_table(:acl) do
      primary_key :id
      column :owner_id, "integer", :null=>false
      column :name, "text", :null=>false
      column :permission, "text", :null=>false
      column :members, "text[]"
      column :documents, "integer[]"
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"
    end
  end
end
