# frozen_string_literal: true

require 'rspec'
require_relative '../parser'
require_relative '../tokenizer'

# Low level unit tests - can delete later
RSpec.describe(TextParser) do
    subject { TextParser.new }

    it "matches a text token" do
        tokens = [TextToken.new('hello')]
        expect(subject.match(tokens)).to eq(TextNode.new(value: 'hello', consumed: 1))
    end

    it "doesn't match an underscore token" do
        tokens = [:underscore, TextToken.new('hello')]
        expect(subject.match(tokens)).to be_nil
    end
end

RSpec.describe(BoldTextParser) do
    subject { BoldTextParser.new }

    it "matches **TEXT**" do
        tokens = [:star, :star, TextToken.new('hello'), :star, :star]
        expect(subject.match(tokens)).to eq(BoldTextNode.new(value: 'hello', consumed: 5))
    end

    it "matches __TEXT__" do
        tokens = [:underscore, :underscore, TextToken.new('hello'), :underscore, :underscore]
        expect(subject.match(tokens)).to eq(BoldTextNode.new(value: 'hello', consumed: 5))
    end

    it "doesn't match _TEXT_" do
        tokens = [:underscore, TextToken.new('hello'), :underscore]
        expect(subject.match(tokens)).to be_nil
    end
end

RSpec.describe(Parser) do
    subject { Parser.new }

    describe "#parse" do
        skip "parses a simple example" do
            document = "__Foo__ and *bar*.\n\nAnother paragraph."
            
            result = subject.parse(document)

            expected = BodyNode.new(
                consumed: 14,
                paragraphs: [
                    ParagraphNode.new(
                        consumed: 12,
                        sentences: [               # it's a bit weird these are called sentences?
                            BoldTextNode.new(
                                consumed: 5,
                                value: "Foo"
                            ),
                            TextNode.new(
                                consumed: 1,
                                value: " and "
                            ),
                            EmphasisedTextNode.new(
                                consumed: 3,
                                value: "bar"
                            ),
                            TextNode.new(
                                consumed: 1,
                                value: "."
                            )
                        ]
                    ),
                    ParagraphNode.new(
                        consumed: 2,
                        sentences: [
                            TextNode.new(consumed: 1, value: "Another Paragraph.")
                        ]
                    )
                ]
            )

            expect(result).to eq(expected)
        end
    end
end