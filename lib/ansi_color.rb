# frozen_string_literal: true

module ANSIColor
  ESCAPE = "\e["
  RESET = '0m'
  CODES = {
    black: '30',
    red: '31',
    green: '32',
    yellow: '33',
    blue: '34',
    magenta: '35',
    cyan: '36',
    white: '37'
  }.freeze

  CODES.each do |name, code|
    define_method(name) do |string, bold: false|
      color(string, code: code, bold: bold)
    end
  end

  def color(string, code:, bold: false)
    attributes = bold ? "#{code};1" : code
    "#{ESCAPE}#{attributes}m#{string}#{ESCAPE}#{RESET}"
  end
end
