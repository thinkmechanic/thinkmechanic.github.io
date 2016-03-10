require 'date'

module Jekyll
  module DateFilter
    def pretty(date)
      "#{date.strftime('%B')} #{ordinalize(date)}, #{date.strftime('%Y')}"
    end

    private

    def ordinalize(date)
      number = date.strftime('%e').to_i.abs

      ord = if (11..13).include?(number % 100)
        "th"
      else
        case number % 10
          when 1; "st"
          when 2; "nd"
          when 3; "rd"
          else    "th"
        end
      end

      "#{number}#{ord}"
    end
  end
end

Liquid::Template.register_filter(Jekyll::DateFilter)
