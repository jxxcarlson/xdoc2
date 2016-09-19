
### INTERFACE ###
# AWS.upload
# AWS.put_string
# AWS.get_string
module AWS
  require 'aws-sdk'

  ### INTERFACE ###

  def self.upload(file_name, tmpfile, folder='tmp')

    bucket = "vschool"

    s3 = Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
        region: 'us-west-1',
        endpoint: 'https://s3.amazonaws.com'
    )

    base_name = File.basename(file_name)

    obj = s3.bucket(bucket).object("#{folder}/#{base_name}")
    obj.upload_file(tmpfile, acl: 'public-read')

    return obj.public_url

  end


  # create file on S3 from string str\
  # http://docs.aws.amazon.com/AmazonS3/latest/dev/UploadObjSingleOpRuby.html
  def self.put_string(str, object_name, folder='tmp')

    bucket = "psurl"
    object_name = "#{folder}/#{object_name}"
    # mime_type = "application/octet-stream"

    s3 = Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
        region: 'us-west-1',
        endpoint: 'https://s3.amazonaws.com'
    )

    obj = s3.bucket(bucket).object(object_name)

    obj.put(body: str,  acl: 'public-read')

  end

  # read file on S3 and return it as a string
  # https://ruby.awsblog.com/post/Tx354Y6VTZ421PJ/Downloading-Objects-from-Amazon-S3-using-the-AWS-SDK-for-Ruby
  # Example: str = AWS.get_string("craig-210-backup-1.json", "backups/craig")
  def self.get_string(object_name, folder='tmp')

    bucket = "psurl"
    object_name = "#{folder}/#{object_name}"
    # mime_type = "application/octet-stream"

    s3 = Aws::S3::Client.new(
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
        region: 'us-west-1',
        endpoint: 'https://s3.amazonaws.com'
    )


    resp = s3.get_object(bucket: bucket, key: object_name)

    resp.body.read

  end

  # AWS.copy_object('psurl', 'monarch.jpg', 'psurl', 'images/jc/monarch.jpg')
  #   =>
  #   http://psurl.s3.amazonaws.com/images/jc/monarch.jpg
  #
  def copy_object(source_bucket, source_object, target_bucket, target_object, options={})


    s3 = Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
        region: 'us-west-1',
        endpoint: 'https://s3.amazonaws.com'
    )

    obj = s3.bucket(source_bucket).object(source_object)

    target = "#{target_bucket}/#{target_object}"

    if options[:public] == 'yes'

      obj.copy_to(target, acl: 'public-read')

    else

      obj.copy_to(target)

    end



  end

  def move_object(source_bucket, source_object, target_bucket, target_object, options={})

    s3 = Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
        region: 'us-west-1',
        endpoint: 'https://s3.amazonaws.com'
    )

    obj = s3.bucket(source_bucket).object(source_object)

    target = "#{target_bucket}/#{target_object}"

    return false if (!obj.exists?)


    if options[:public] == 'yes'

      obj.move_to(target, acl: 'public-read')

    else

      obj.move_to(target)

    end

    return true
  end

  # Example: AWS.list('psurl', 'backups/craig/')
  def list(bucket, folder,options={})

    s3 = Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
        region: 'us-west-1',
        endpoint: 'https://s3.amazonaws.com'
    )

    data_files = s3.bucket(bucket).objects(prefix: folder).collect(&:key)

    return data_files
  end

  def make_log(user_name)
    # user = UserRepository.find_by_username user_name
    eol = "\n"
    log = ""
    log << {"title": "Backup log for #{user_name}" }.to_json << eol
    log_files = list('psurl', "backups/#{user_name}/")
    log_files.each do |log_file_name|
      log_file_name = log_file_name.sub("backups/", '')
      puts "Getting #{log_file_name}"
      log_data = JSON.parse get_string(log_file_name, "backups")
      dict = log_data['dict'] || {}
      bu = dict['backup'] || {}
      puts bu =
      log_item = {
          'id': log_data['id'],
          'title': log_data['title'],
          'backup_number': bu['number'],
          'timestamp': bu['date']
      }.to_json
      log << log_item << eol
    end
    put_string(log, "#{user_name}.log", "backups/#{user_name}")
    log
  end

end