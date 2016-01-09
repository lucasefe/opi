module Opi
  class StatementParser
    def initialize(text)
      @text = text
    end

    def year
      @year ||= @text.match(/Resumen Galicia al (\d*)-(\d*)-(\d*)/)[3].split(' ').last
    end

    def accounts
      @accounts ||= parse_accounts(@text)
    end

    def process
      records = []  
      
      accounts.each do |account, lines|
        puts account, lines.size
        #records += process_lines(card, lines, year)
      end
      #records.map { |l| l.values.inspect[1..-2] }.join("\n")
    end

    private

    CCP_REGEX = /Cuenta Corriente en Pesos Nro. (.*)/
    CAP_REGEX = /Caja de Ahorros en Pesos Nro. (.*)/
    CAD_REGEX = /Caja de Ahorros en Dólares Nro. (.*)/

    def parse_accounts(text)
      accounts = {}
      lines = []
      current_account = nil
      start = false

      text.split("\n").each do |line|
        m = line.match(CCP_REGEX) || line.match(CAP_REGEX) || line.match(CAD_REGEX)
        
        if m 
          start = true
          account = m[1].split(' ')[0..1].join(' ').strip
          if current_account != account
            current_account = account
            accounts[current_account] = []
          end
        else
          accounts[current_account].push(line) if start && current_account
        end
      end

      accounts
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
      format('%s/%s/20%s', month, day, year)
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