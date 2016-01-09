require 'yomu'
require 'ostruct'
require_relative 'credit_card_parser'
require_relative 'statement_parser'

module Opi
  # Parser
  module Parser
    module_function

    def process(text)
      title = text.split("\n")[1].strip
      
      if title == "VISA" || title == "RESUMEN DE CUENTA"
        parser = CreditCardParser.new(text)
      else
        parser = StatementParser.new(text)
      end

      parser.process
    end
  end
end
