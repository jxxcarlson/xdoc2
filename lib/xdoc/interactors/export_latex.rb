require 'hanami/interactor'
require_relative 'render_asciidoc'

class LatexExporter

  include Hanami::Interactor
  include Asciidoctor

  expose :tar_url


  def initialize(id)
    @document = DocumentRepository.find id
    @source = @document.text
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

  def use_latex_macros
    if @document.text =~ /include_latex_macros::default/
      tex_macro_file_name = "#{@document.author_name}.tex"
      tex_macros = AWS.get_string(tex_macro_file_name, folder='latex_macros')
      if tex_macros
        @source = @document.text.sub('include_latex_macros::default[]', "\n++++\n\\(\n\n#{tex_macros}\n\\)\n++++\n")
      end
    else
      @source = @document.text
    end
  end


  def export
    preamble = AWS.get_string("preamble.tex", "strings")
    prefix = preamble
    prefix <<  "\n\n\\title{#{@document.title}}"
    prefix << "\n\n\\begin{document}\n\n"
    prefix << "\n\n\\maketitle"
    prefix << "\n\n\\tableofcontents"
    prefix << "\n\n"
    suffix = "\n\n\\end{document}n\n"

    options = { :safe => :safe, :source_highlighter => :coderay, :coderay_css => :class, :backend => 'latex' }
    latex_text = Asciidoctor.convert @source, options
    latex_text = prefix + latex_text + suffix

    file_name = normalize @document.title
    system("mkdir -p outgoing/#{@document.id}")

    path = "outgoing/#{@document.id}/#{file_name}.tex"
    IO.write(path, latex_text)

    path = "outgoing/#{@document.id}/#{file_name}.adoc"
    IO.write(path, @document.text)
  end

  def tar
    system("mkdir -p outgoing/tar")
    system("cd outgoing; tar -cvf ./tar/#{@document.id}.tar #{@document.id}/; cd ..")
  end

  def upload
    AWS.upload2('psurl', "latex/#{@document.id}.tar", "outgoing/tar/#{@document.id}.tar")
  end

  def call
    use_latex_macros
    rewrite_media_urls_for_export
    export
    tar
    upload
    @tar_url = "http://psurl.s3.amazonaws.com/latex/#{@document.id}.tar"
  end


end