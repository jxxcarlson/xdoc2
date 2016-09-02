class Image
  include Hanami::Entity

  attributes :id, :title, :owner_id, :created_at, :updated_at,
      :url, :source, :public, :dict, :tags, :content_type, :bucket, :path, :file


  def hash
    { :id => self.id, :title => self.title, :storage_url => self.url, :source => self.source,
      :url => "/images/#{self.id}", :tags =>  self.stringify_tags , :content_type => self.content_type}
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

  def self.update_metadata
    ImageRepository.all.each do |image|
      url = image.url.sub('http://', '')
      url = url.sub('https://', '')
      parts = url.split('/')
      if parts.count == 2
        bucket = parts[0]
        file = parts[-1]
        image.bucket = bucket
        image.path = ''
        image.file = file
        ImageRepository.update image
      elsif parts.count === 3
        bucket = parts[0]
        path = parts[-2]
        file = parts[-1]
        image.bucket = bucket
        image.path = path
        image.file = file
        ImageRepository.update image
      end
      puts "#{image.id}\t #{image.title[0..10]}::\t #{image.bucket}\t #{image.path}\t #{image.file}"

    end
    "end"
  end

  def self.check_metadata
    count = 0
    ImageRepository.all.each do |image|
      if image.url != image.synthetic_url
        count += 1
        puts "#{image.id}\t #{image.title}\t #{image.url} -- #{image.synthetic_url}"
      end
    end
    count
  end

  def synthetic_url
    self.path ||= ''
    if path == ''
      url = "http://#{self.bucket}/#{self.file}"
    else
      url = "http://#{self.bucket}/#{path}/#{self.file}"
    end
    url
  end

end

