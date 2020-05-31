# frozen_string_literal: true

require 'pry'

TextToken = Struct.new(:text)

class SymbolScanner
  def initialize(symbol, token)
    @symbol = symbol
    @token = token
  end

  def consume(text)
    if text[0] == symbol
      [token, text[1..]]
    else
      [nil, text]
    end
  end

  private

  attr_reader :symbol, :token
end

class TextScanner
  def self.consume(text)
    symbols = /[*_\n]/
    return [null, text] if text.empty? || symbols =~ text[0]

    first_symbol = text.index(symbols)
    token = TextToken.new(text[0...first_symbol])

    [token, text[first_symbol..]]
  end
end

class Tokenizer
  def initialize
    @scanners = [
      SymbolScanner.new('_', :underscore),
      SymbolScanner.new('*', :star),
      SymbolScanner.new("\n", :newline),
      TextScanner
    ]
  end

  def tokenize(plain_markdown)
    tokens = []

    loop do
      return tokens + [:end_of_file] if plain_markdown.empty?

      token = nil

      scanners.each do |scanner|
        token, plain_markdown = scanner.consume(plain_markdown)
        break unless token.nil?
      end

      raise 'SyntaxError' if token.nil?

      tokens << token
    end

    tokens + [:end_of_file]
  end

  private

  attr_reader :scanners
end
