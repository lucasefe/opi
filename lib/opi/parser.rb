require 'yomu'
require 'ostruct'

module Opi
  class Parser
    def initialize(text)
      @text = text
    end

    def process
      records = []
      year = @text.match(/VENCIMIENTO(.*)CIERRE(.*)/)[2].split(' ').last
      cards = parse_cards(@text)
      cards.each do |card, lines|
        records += process_lines(card, lines, year)
      end
      records.map { |l| l.values.inspect[1..-2] }.join("\n")
    end

    private

    def parse_cards(text)
      cards = {}
      lines = []
      start = false
      text.split("\n").each do |line|
        start = true if line.match(/______/)

        if start
          m = line.match(/Total Consumos de (.*)/)
          if m
            card = m[1].split(' ').first
            cards[card] = lines
            lines = []
          else
            lines.push(line)
          end
        end
      end
      cards
    end

    def process_lines(card, lines, year)
      last_date = ''
      validate_lines(lines).map do |line|
        record = OpenStruct.new
        date = line[0..10]
        last_date = record.date = date.strip == '' ? last_date : parse_date(date, year)
        record.card = card
        record.ref = line[14..19]
        if line[50..52] == 'USD'
          record.description = line[24..49].strip
          record.currency = 'USD'
          record.amount = parse_amount(line[54..65])
        else
          record.description = line[24..80].strip
          record.currency = 'PESOS'
          record.amount = parse_amount(line[81..91])
        end
        record.marshal_dump
      end
    end

    def validate_lines(lines)
      lines.map do |line|
        next unless process_line?(line)
        line
      end.compact
    end

    def process_line?(line)
      line[13..21] =~ /\s\d{6}\s/
    end

    def parse_date(date, year)
      day = date[0..1]
      month = parse_month(date[3..-1])
      sprintf('%s/%s/20%s', month, day, year)
    end

    def parse_amount(amount)
      amount.gsub(',', '.').strip
    end

    def parse_month(month)
      case month.downcase[0..2]
      when 'ene' then '01'
      when 'feb' then '02'
      when 'mar' then '03'
      when 'abr' then '04'
      when 'may' then '05'
      when 'jun' then '06'
      when 'jul' then '07'
      when 'ago' then '08'
      when 'sep' then '09'
      when 'oct' then '10'
      when 'nov' then '11'
      when 'dic' then '12'
      else
        fail "Invalid month: #{month}"
      end
    end
  end
end
