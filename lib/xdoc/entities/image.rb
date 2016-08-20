class Image
  include Hanami::Entity

  attributes :id, :title, :owner_id, :created_at, :updated_at,
      :url, :source, :public, :dict, :tags, :content_type


  def hash
    { :id => self.id, :title => self.title, :storage_url => self.url, :source => self.source,
      :url => "/images/#{self.id}", :tags =>  self.stringify_tags }
  end

  def stringify_tags
    str = ''
    tags = self.tags
    if tags.count > 0
      self.tags[0..-2].each do |tag|
        str += tag + ', '
      end
      str += tags[-1]
    end
    str
  end

  def update_tags_from_string(str)
    self.tags = str.gsub(' ', '').split(',')
    ImageRepository.update self
  end

end

