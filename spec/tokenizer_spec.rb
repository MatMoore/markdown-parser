# frozen_string_literal: true

require 'rspec'
require_relative '../tokenizer'

RSpec.describe(Tokenizer) do
  it 'parses *' do
    tokens = Tokenizer.new.tokenize('*')
    expect(tokens).to eq(%i[star end_of_file])
  end

  it 'parses _' do
    tokens = Tokenizer.new.tokenize('_')
    expect(tokens).to eq(%i[underscore end_of_file])
  end

  it 'parses symbols seperated by a newline' do
    tokens = Tokenizer.new.tokenize("_\n_")
    expect(tokens).to eq(%i[underscore newline underscore end_of_file])
  end

  it 'parses _Hello*' do
    tokens = Tokenizer.new.tokenize('_Hello*')

    expect(tokens).to eq([
                           :underscore,
                           TextToken.new('Hello'),
                           :star,
                           :end_of_file
                         ])
  end
end
