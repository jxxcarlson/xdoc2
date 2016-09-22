require 'hanami/interactor'

# API:
#
#  checkout=ID&user=USER      :: check out document with id = ID to USER
#  checkin=ID&user=USER       :: check in document with id = ID by USER
#  status=ID                  :: return username of person who has checked out this document
#  toggle=ID&user=USER        :: toggle status
#
class CheckoutManager

  include Hanami::Interactor

  expose :status, :reply

  def initialize(command)
    @commands = command.split('&').map{ |command| command.split('=') }
    puts "CheckoutManager, @commands #{@commands}"
    @status = 'error'
  end

  def status
    document_id = @object
    document = DocumentRepository.find document_id
    if document
      @reply = document.checked_out_to
      @status = 'success'
    end
  end

  def checkout
    document_id = @object
    document = DocumentRepository.find document_id
    if document
      _command, username = @commands.shift
      user = UserRepository.find_by_username username
      return if user == nil
      @reply = document.check_out_to username
      @status = 'success'
    end
  end

  def checkin
    document_id = @object
    document = DocumentRepository.find document_id
    if document
      _command, username = @commands.shift
      user = UserRepository.find_by_username username
      return if user == nil
      @reply = document.check_in_by username
      @status = 'success'
    end
  end

  def toggle
    document_id = @object
    document = DocumentRepository.find document_id
    if document
      _command, username = @commands.shift
      user = UserRepository.find_by_username username
      return if user == nil
      @reply = document.checkout_toggle username
      @status = 'success'
    end
  end



  def call
    @verb, @object = @commands.shift
    send @verb
   end


end
