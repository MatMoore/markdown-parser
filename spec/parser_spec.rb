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

RSpec.describe(EmphasisedTextParser) do
    subject { EmphasisedTextParser.new }

    it "matches *TEXT*" do
        tokens = [:star, TextToken.new('hello'), :star]
        expect(subject.match(tokens)).to eq(EmphasisedTextNode.new(value: 'hello', consumed: 3))
    end

    it "matches _TEXT_" do
        tokens = [:underscore, TextToken.new('hello'), :underscore]
        expect(subject.match(tokens)).to eq(EmphasisedTextNode.new(value: 'hello', consumed: 3))
    end
end

RSpec.describe(SentenceParser) do
    subject { SentenceParser.new }
    
    it "matches **TEXT**" do
        tokens = [:star, :star, TextToken.new('hello'), :star, :star]
        bolded = BoldTextNode.new(value: 'hello', consumed: 5)

        expect(subject.match(tokens)).to eq(bolded)
    end

    it "matches __TEXT__" do
        tokens = [:underscore, TextToken.new('hello'), :underscore]
        emphasised = EmphasisedTextNode.new(value: 'hello', consumed: 3)

        expect(subject.match(tokens)).to eq(emphasised)
    end

    it "matches TEXT" do
        tokens = [TextToken.new('hello')]
        text = TextNode.new(value: 'hello', consumed: 1)

        expect(subject.match(tokens)).to eq(text)
    end

    it "matches only the part that can be recognised by a single parser" do
        tokens = [TextToken.new('hello'), :underscore, TextToken.new('hello'), :underscore]
        text = TextNode.new(value: 'hello', consumed: 1)

        expect(subject.match(tokens)).to eq(text)
    end
end

RSpec.describe(SentenceAndNewLineParser) do
    subject { SentenceAndNewLineParser.new }

    it "DOESN'T parse TEXT\n" do
        tokens = [TextToken.new('hello'), :newline]
        
        text_node = TextNode.new(value: 'hello', consumed: 1)
        expect(subject.match(tokens)).to be_nil
    end

    it "parses TEXT\n\n" do
        tokens = [TextToken.new('hello'), :newline, :newline]
        
        text_node = TextNode.new(value: 'hello', consumed: 1)
        expect(subject.match(tokens)).to eq(ParagraphNode.new(sentences: [text_node], consumed: 3))
    end

    it "parses multiple sentences" do
        tokens = [TextToken.new('hello'), :star, TextToken.new('world'), :star, :newline, :newline]
        
        hello = TextNode.new(value: 'hello', consumed: 1)
        world = EmphasisedTextNode.new(value: 'world', consumed: 3)
        expect(subject.match(tokens)).to eq(ParagraphNode.new(sentences: [hello, world], consumed: 6))
    end

    it "stops at a pair of newlines" do
        tokens = [TextToken.new('hello'), :newline, :newline, TextToken.new('world'), :newline]

        text_node = TextNode.new(value: 'hello', consumed: 1)
        expect(subject.match(tokens)).to eq(ParagraphNode.new(sentences: [text_node], consumed: 3))
    end

    it "doesn't consumes more than 2 newlines" do
        tokens = [TextToken.new('hello'), :newline, :newline, :newline]

        text_node = TextNode.new(value: 'hello', consumed: 1)
        expect(subject.match(tokens)).to eq(ParagraphNode.new(sentences: [text_node], consumed: 3))
    end
end

RSpec.describe(SentenceAndEOFParser) do
    subject { SentenceAndEOFParser.new }

    it "parses a sentence at the end of the file" do
        tokens = [TextToken.new('hello'), :end_of_file]
        
        text_node = TextNode.new(value: 'hello', consumed: 1)
        expect(subject.match(tokens)).to eq(ParagraphNode.new(sentences: [text_node], consumed: 2))
    end

    it "parses a sentence with a newline at the end of the file" do
        tokens = [TextToken.new('hello'), :newline, :end_of_file]
        
        text_node = TextNode.new(value: 'hello', consumed: 1)
        expect(subject.match(tokens)).to eq(ParagraphNode.new(sentences: [text_node], consumed: 3))
    end
end

RSpec.describe(ParagraphParser) do
    subject { ParagraphParser.new }

    it "parses a paragraph at the end of the file" do
        tokens = [TextToken.new('hello'), :end_of_file]
        
        text_node = TextNode.new(value: 'hello', consumed: 1)
        expect(subject.match(tokens)).to eq(ParagraphNode.new(sentences: [text_node], consumed: 2))
    end

    it "parses a paragraph in the middle of the file" do
        tokens = [TextToken.new('hello'), :newline, :newline, TextToken.new('world')]
        
        text_node = TextNode.new(value: 'hello', consumed: 1)
        expect(subject.match(tokens)).to eq(ParagraphNode.new(sentences: [text_node], consumed: 3))
    end
end

RSpec.describe(BodyParser) do
    subject { BodyParser.new }

    it "parses some text" do
        tokens = [TextToken.new('hello'), :end_of_file]

        text_node = TextNode.new(value: 'hello', consumed: 1)
        paragraph_node = ParagraphNode.new(sentences: [text_node], consumed: 2)
        body_node = BodyNode.new(paragraphs: [paragraph_node], consumed: 2)

        expect(subject.match(tokens)).to eq(body_node)
    end

    it "parses multiple paragraphs" do
        tokens = [TextToken.new('hello'), :newline, :newline, TextToken.new('world'), :newline, :end_of_file]

        hello_node = TextNode.new(value: 'hello', consumed: 1)
        world_node = TextNode.new(value: 'world', consumed: 1)
        first_para_node = ParagraphNode.new(sentences: [hello_node], consumed: 3)
        second_para_node = ParagraphNode.new(sentences: [world_node], consumed: 3)
        body_node = BodyNode.new(paragraphs: [first_para_node, second_para_node], consumed: 6)

        expect(subject.match(tokens)).to eq(body_node)
    end
end

RSpec.describe(Parser) do
    subject { Parser.new }

    describe "#parse" do
        it "parses a single paragraph example" do
            document = "__Foo__ and *bar*."
            
            result = subject.parse(document)
            expect(result).not_to be_nil
        end

        it "parses a two paragraph example" do
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
                            TextNode.new(consumed: 1, value: "Another paragraph.")
                        ]
                    )
                ]
            )

            expect(result).to eq(expected)
        end
    end
end