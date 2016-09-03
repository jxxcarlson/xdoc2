

require 'aws-sdk'
require_relative '../../xdoc/modules/utility'

include Utility
include SecureRandom

class Image
  include Hanami::Entity

  attributes :id, :title, :owner_id, :created_at, :updated_at,
      :url, :source, :public, :dict, :tags, :content_type, :bucket, :path, :file


  def hash
    { :id => self.id, :title => self.title, :storage_url => self.url, :source => self.source,
      :url => "/images/#{self.id}", :tags =>  self.stringify_tags , :content_type => self.content_type}
  end

  def stringify_tags
    tags = self.tags || []
    if tags != []
      self.tags.join(', ')[0..-2]
    else
      ''
    end
  end

  def stringify_tags_old
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

  def move
    source_bucket = 'psurl'
    target_bucket = 'psurl'

    source_object = self.file
    insertion = "-#{SecureRandom.hex(2)}"
    source_object2 = Utility.insert_into_string(source_object, insertion, '.')
    puts "source_object2: #{source_object2}"

    owner = UserRepository.find self.owner_id
    target_path = "images/#{owner.username}"
    target_object = "#{target_path}/#{source_object2}"

    self.path = target_path
    self.bucket = 'psurl'

    new_url = "http://psurl.s3.amazonaws.com/#{target_object}"

    self.url = new_url
    ImageRepository.update self

    AWS.move_object(source_bucket, source_object, target_bucket, target_object, {public: 'yes'})
  end

end

