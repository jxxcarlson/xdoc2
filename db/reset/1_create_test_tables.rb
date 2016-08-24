Sequel.migration do
  change do
    create_table(:acl) do
      primary_key :id
      column :owner_id, "integer", :null=>false
      column :name, "text", :null=>false
      column :permission, "text", :null=>false
      column :members, "text[]"
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"
    end

    create_table(:documents) do
      primary_key :id
      column :identifier, "text"
      column :title, "text", :null=>false
      column :owner_id, "integer"
      column :collection_id, "integer"
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"
      column :viewed_at, "timestamp without time zone"
      column :visit_count, "integer"
      column :text, "text", :null=>false
      column :rendered_text, "text"
      column :kind, "text"
      column :public, "boolean"
      column :dict, "jsonb"
      column :tags, "text[]"
      column :links, "jsonb"
      column :author_name, "text"
    end

    create_table(:images) do
      primary_key :id
      column :title, "text", :null=>false
      column :owner_id, "integer"
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"
      column :url, "text", :null=>false
      column :source, "text"
      column :public, "boolean"
      column :dict, "jsonb"
      column :tags, "text[]"
      column :content_type, "text"
    end


    create_table(:users) do
      primary_key :id
      column :username, "text", :null=>false
      column :admin, "boolean"
      column :status, "text"
      column :email, "text"
      column :password_hash, "text"
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"
      column :dict, "jsonb"
      column :links, "jsonb"
    end
  end
end