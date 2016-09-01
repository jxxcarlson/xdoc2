require 'hanami/interactor'
require_relative '../../../lib/xdoc/modules/aws'

include AWS

# API:
#
#  prepare_backups=USERNAME            :: set up log file USERNAME.log
#  put_backup=ID                       :: make a backup of document with id = ID
#  get_backup=latest

class BackupManager

  include Hanami::Interactor

  expose :backup_number, :status, :log

  def initialize(command)
    @commands = command.split('&').map{ |commmand| command.split('=') }
    puts "Commands: #{@commands}"
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
    end
  end

end
