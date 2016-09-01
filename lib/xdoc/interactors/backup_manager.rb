require 'hanami/interactor'
require_relative '../../../lib/xdoc/modules/aws'

include AWS

# API:
#
#  prepare_backups=USERNAME            :: set up log file USERNAME.log
#  put_backup=ID                       :: make a backup of document with id = ID
#  read_log=USER&title=TITLE           ;: return log entries for user=USER and doc title like TITLE
#
#
class BackupManager

  include Hanami::Interactor

  expose :backup_number, :status, :log, :log_as_json, :report

  def initialize(command)
    @commands = command.split('&').map{ |command| command.split('=') }
    @report = 'none'
    @status = 'error'
  end

  def prepare_backups
    username = @object
    puts "prepare_backups: #{username}"
    message = {title: "Backup log for #{username}"}.to_json + "\n"
    object_name = "#{username}.log"
    AWS.put_string(message, object_name, 'backups')
    @status = 'success'
  end

  def get_log(username)
    @log = AWS.get_string("#{username}.log", 'backups')
  end

  def append_to_log(username, message)
    get_log(username)
    @log << message << "\n"
    object_name = "#{username}.log"
    AWS.put_string(@log, object_name, 'backups')
  end

  def parse_log
    log_lines= @log.split("\n")
    log_lines.shift # discard title line
    @log_as_json = log_lines.map{ |line| JSON.parse line}
  end

  def select_backups_for_title(title)
    title = title.downcase
    @log_as_json = @log_as_json.select{ |item| item['title'].downcase =~ /#{title}/}
  end

  def read_log
    username = @object
    get_log(username)
    parse_log
    _verb, title = @commands.shift
    select_backups_for_title(title)
    str = "-------------------------------------------------------------------------" << "\n"
    str << "Report\n"
    str << "-------------------------------------------------------------------------" << "\n"
    str << "N\t ID\t TITLE\t\t LENGTH\t WHEN\n"
    str << "-------------------------------------------------------------------------" << "\n"
    @log_as_json.each do |item|
      str << "#{item['backup_number']}\t #{item['id']}\t #{item['title']}\t #{item['length']}\t #{item['timestamp']}" << "\n"
    end
    str << "-------------------------------------------------------------------------" << "\n"
    str << "Items: #{@log_as_json.count}" << "\n"
    str << "-------------------------------------------------------------------------" << "\n"
    @report = str
    puts @report
    @status = 'success'
    @log_as_json.count
  end


  def put_backup
    document_id = @object
    @document = DocumentRepository.find document_id
    @backup_number = (@document.backup_number || 0) + 1
    backup_string = @document.to_hash.to_json
    object_name = "#{@document.author_name}-#{@document.id}-backup-#{@backup_number}.json"
    AWS.put_string(backup_string, object_name, 'backups')
    @document.backup_number = @backup_number
    DocumentRepository.update @document
    message = {id: @document.id, title: @document.title, backup_number: @backup_number, length: @document.text.length, timestamp: DateTime.now.to_s }.to_json
    append_to_log(@document.author_name, message)
    @status = 'success'
  end

  def call
    @verb, @object = @commands.shift
    case @verb
      when 'put'
        put_backup
      when 'prepare_backups'
        prepare_backups
      when 'get_log'
        get_log(@object)
      when 'read_log'
        read_log
    end
  end

end
