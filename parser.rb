require_relative 'tokenizer'

TextNode = Struct.new(:value, :consumed)
BoldTextNode = Struct.new(:value, :consumed)
EmphasisedTextNode = Struct.new(:value, :consumed)
NewlineNode = Struct.new(:value, :consumed)
ParagraphNode = Struct.new(:sentences, :consumed)
BodyNode = Struct.new(:paragraphs, :consumed)

class Parser
    def initialize
        @tokenizer = Tokenizer.new
        @body_parser = BodyParser.new
    end

    def parse(document)
        tokens = tokenizer.tokenize(document)
        body = body_parser.match(tokens)

        raise "Syntax error: #{tokens[body.consumed]}" unless tokens.count == body.consumed
    end

    private

    attr_reader :tokenizer
    attr_reader :body_parser
end

class BodyParser
    def match(tokens)
        BodyNode.new([], 0)
    end
end

class TextParser
    def match(tokens)
        return nil unless tokens.first.is_a?(TextToken)

        TextNode.new(value: tokens.first.text, consumed: 1)
    end
end

class BoldTextParser
    def match(tokens)
        underscore_pattern = PatternBuilder.new
            .underscore
            .underscore
            .text
            .underscore
            .underscore

        star_pattern = PatternBuilder.new
            .star
            .star
            .text
            .star
            .star

        if underscore_pattern.matches?(tokens) || star_pattern.matches?(tokens)
           BoldTextNode.new(value: tokens[2].text, consumed: 5)
        end
    end
end
