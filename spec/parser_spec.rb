# frozen_string_literal: true

require 'rspec'
require_relative '../parser'

RSpec.describe("Parser") do
    subject { Parser.new }

    describe "#parse" do
        it "parses a simple example" do
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