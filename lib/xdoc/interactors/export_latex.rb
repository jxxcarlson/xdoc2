require 'hanami/interactor'

class LatexExporter

  include Hanami::Interactor

  expose :tar_url


  def initialize(id)
    @document = DocumentRepository.find id
    puts "*** TITLE: #{@document.title}"
    @source = @document.text
    puts "*** TEXT: #{@document.title[0..40]}"
  end

  def normalize(str)
    str = str.gsub(' ', '_').downcase
    str = str.gsub(/[^a-zA-Z_]/, '')
    str.gsub(/_*_/, '_')
  end


  def rewrite_media_urls_for_export

    system("mkdir -p outgoing/#{@document.id}/images")

    rxTag = /(image|video|audio)(:+)(.*?)\[(.*)\]/
    scanner = @source.scan(rxTag)
    count = 0

    scanner.each do |scan_item|
      count += 1

      media_type = scan_item[0]
      infix = scan_item[1]
      id = scan_item[2]
      attributes = scan_item[3]

      old_tag = "#{media_type}#{infix}#{id}[#{attributes}]"

      if id =~ /^\d+\d$/
        iii = ImageRepository.find id
        if iii
          download_file_name = iii.file
          download_path = "outgoing/#{@document.id}/images/#{download_file_name}"
          new_tag = "#{media_type}::images/#{download_file_name}[#{attributes}]"
          AWS.download('psurl', iii.s3_key, download_path)
          @source = @source.sub(old_tag, new_tag)
        end
      end

    end

  end


  def export
    puts '*** AA'
    preamble = AWS.get_string("preamble.tex", "strings")
    prefix = preamble
    prefix <<  "\n\n\\title{#{@document.title}}"
    prefix << "\n\n\\begin{document}\n\n"
    prefix << "\n\n\\maketitle"
    prefix << "\n\n\\tableofcontents"
    prefix << "\n\n"
    suffix = "\n\n\\end{document}n\n"

    puts '*** BB'
    @source = prefix + @source + suffix
    renderer = ::RenderAsciidoc.new(source_text: @source, options: {:backend => 'latex'}).call
    latex_text = renderer.rendered_text

    puts "Latex text: #{latex_text}"
    puts '*** BBBBB'

    file_name = normalize @document.title
    system("mkdir -p outgoing/#{@document.id}")

    puts '*** BB'
    puts "latex_text: #{latex_text.length} characters"
    # path = "outgoing/#{@document.id}/#{file_name}.tex"
    path = "#{@document.id}/#{file_name}.tex"
    IO.write(path, latex_text)

    puts '*** CC'
    path = "outgoing/#{@document.id}/#{file_name}.adoc"
    IO.write(path, @document.text)
    puts '*** DD'
  end

  def tar
    system("mkdir -p outgoing/tar")
    system("cd outgoing; tar -cvf ./tar/#{@document.id}.tar #{@document.id}/; cd ..")
  end

  def upload
    AWS.upload2('psurl', "latex/#{@document.id}.tar", "outgoing/tar/#{@document.id}.tar")
  end

  def call
    puts '*** A'
    rewrite_media_urls_for_export
    puts '*** B'
    export
    puts '*** C'
    tar
    puts '*** D'
    upload
    puts '*** E'
    @tar_url = "http://psurl.s3.amazonaws.com/latex/#{@document.id}.tar"
    puts '*** F'
  end


end