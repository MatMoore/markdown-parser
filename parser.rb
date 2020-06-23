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