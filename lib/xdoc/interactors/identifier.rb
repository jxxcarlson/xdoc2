require 'hanami/interactor'


class Identifier
  include Hanami::Interactor

  expose :status, :identifier

  def initialize(trial_identifier, document)

    @document = document
    @trial_identifier = trial_identifier
    @status = 'error'

  end

  def call

    # Set default trial identifier if input is nil or ''
    if @trial_identifier == nil || @trial_identifier == ''
      @trial_identifier  = @document.title
    end

    # Restrict identifier to user's name space: first, remove it
    # if it is there to avoid duplicaton, then prefix username
    @identifier = @trial_identifier.gsub(/\A#{@document.author_name}\./, '')
    @identifier = "#{@document.author_name}.#{@identifier}".downcase.gsub(' ', '_')
    # Ensure that the identifier is unique by adding a short hash if necessary
    _document = DocumentRepository.find_by_identifier @trial_identifier
    if _document != nil && _document != @document
      @identifier = "#{@identifier}.#{SecureRandom.hex(2)}"
      _document = DocumentRepository.find_by_identifier @identifier
      if _document != nil && _document != @document
        @identifier = "#{@identifier}.#{SecureRandom.hex(4)}"
      end
      _document = DocumentRepository.find_by_identifier @identifier
      if _document != nil && _document != @document
        @identifier = "#{@identifier}.#{SecureRandom.hex(6)}"
      end
    end

    @status = 'success'
    @document.identifier = @identifier
    DocumentRepository.update @document

  end

end
