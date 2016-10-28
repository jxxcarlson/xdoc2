require 'hanami/interactor'
require_relative 'identifier'


# Create home page for user with given text
class CreateHomePage

  include Hanami::Interactor
  include Asciidoctor


  expose :new_document, :parent_document, :status

  def initialize(user, text)
    @user = user
    @params = {:title=>"#{@user.username}.home", :options=>{}, :text=> text, :current_document_id=>0, :parent_document_id=>0}
    @author_id = @user.id
    opts = @params['options'] || ""
    if opts.length < 5
      @options = {}
    else
      @options = JSON.parse(opts)
    end
  end

  def create
    document = NSDocument.new(@params)
    author = UserRepository.find @author_id
    document.owner_id = author.id
    document.author_name = author.username
    document.text = @params[:text] || "(Dummy text for ew document #{document.title})"
    document.kind = author.get_preference('doc_format') || 'asciidoc'
    if document.kind == 'text'
      document.rendered_text = document.text
    else
      document.rendered_text = Asciidoctor.convert(document.text)
    end

    puts "*** Document #{document.title} created as #{document.kind}"

    @new_document = DocumentRepository.create document

    Identifier.new(nil, @new_document).call
    puts "CreateDocument: created #{@new_document.title} (#{@new_document.id})"
    @status = 'success'
  end

  def call
    doc = DocumentRepository.find_by_title "#{@user.username}.home"
    create if doc == nil
  end

end




