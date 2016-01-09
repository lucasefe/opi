require 'fileutils'
require_relative 'opi/parser'

module Opi
  module_function

  def read_pdf(pdf)
    decrypted_pdf = sprintf('%s/%s-decrypt.pdf', File.dirname(pdf), File.basename(pdf, '.pdf'))

    # call ghostscript
    `gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=#{decrypted_pdf} -c .setpdfwrite -f #{pdf}`
    text = Yomu.new(decrypted_pdf).text

    yield text

    FileUtils.rm(decrypted_pdf)
  end
end
