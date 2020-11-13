require_relative 'tokenizer'

TextNode = Struct.new(:value, :consumed, keyword_init: true)
BoldTextNode = Struct.new(:value, :consumed, keyword_init: true)
EmphasisedTextNode = Struct.new(:value, :consumed, keyword_init: true)
ParagraphNode = Struct.new(:sentences, :consumed, keyword_init: true)
BodyNode = Struct.new(:paragraphs, :consumed, keyword_init: true)

class Parser
    def initialize
        @tokenizer = Tokenizer.new
        @body_parser = BodyParser.new
    end

    def parse(document)
        tokens = tokenizer.tokenize(document)
        body = body_parser.parse(tokens)

        raise "Syntax error: #{tokens[body.consumed]}" unless tokens.count == body.consumed

        body
    end

    private

    attr_reader :tokenizer
    attr_reader :body_parser
end

class BodyParser
    def initialize
        @many_paragraph_parser = ParseMany.new(ParagraphParser.new)
    end

    def parse(tokens)
        paragraphs = many_paragraph_parser.parse_many(tokens)
        return nil if paragraphs.empty?

        BodyNode.new(paragraphs: paragraphs, consumed: paragraphs.map(&:consumed).sum)
    end

    private

    attr_reader :many_paragraph_parser
end

class TextParser
    def parse(tokens)
        return nil unless tokens.first.is_a?(TextToken)

        TextNode.new(value: tokens.first.text, consumed: 1)
    end
end

class BoldTextParser
    def parse(tokens)
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

class EmphasisedTextParser
    def parse(tokens)
        underscore_pattern = PatternBuilder.new
            .underscore
            .text
            .underscore

        star_pattern = PatternBuilder.new
            .star
            .text
            .star

        if underscore_pattern.matches?(tokens) || star_pattern.matches?(tokens)
           EmphasisedTextNode.new(value: tokens[1].text, consumed: 3)
        end
    end
end

# Not really a sentence, but whatever
class SentenceParser
    def initialize
        text_parser = TextParser.new
        bold_text_parser = BoldTextParser.new
        emphasised_text_parser = EmphasisedTextParser.new
        
        @subparsers = ParseFirst.new([emphasised_text_parser, bold_text_parser, text_parser])
    end

    def parse(tokens)
        subparsers.parse(tokens)
    end

    private

    attr_reader :subparsers
end

class ParagraphParser
    def initialize      
        @subparsers = ParseFirst.new([SentenceAndEOFParser.new, SentenceAndNewLineParser.new])
    end

    def parse(tokens)
        subparsers.parse(tokens)
    end

    private

    attr_reader :subparsers
end

class ParseMany
    def initialize(parser)
        @parser = parser
    end

    def parse_many(tokens)
        nodes = []
        offset = 0
        length = tokens.length

        loop do
            node = parser.parse(tokens[offset..])
            return nodes if node.nil?

            nodes << node
            offset += node.consumed
        end

        return nodes
    end

    private

    attr_reader :parser
end

class ParseFirst
    def initialize(subparsers)
        @subparsers = subparsers
    end

    def parse(tokens)
        subparsers.each do |subparser|
            node = subparser.parse(tokens)

            return node unless node.nil?
        end

        nil
    end

    private

    attr_reader :subparsers
end

# AKA LineParser?
# Bit weird that this returns a ParagraphNode rather than being a seperate node in the parse tree
class SentenceAndNewLineParser
    def initialize
        @many_sentence_parser = ParseMany.new(SentenceParser.new)
    end

    def parse(tokens)
        sentences = many_sentence_parser.parse_many(tokens)
        consumed = sentences.map(&:consumed).sum
        remaining = tokens[consumed...]

        following_newlines = remaining.take_while { |token| token == :newline }.take(2)   
        
        return nil if following_newlines.length < 2

        ParagraphNode.new(sentences: sentences, consumed: consumed + following_newlines.length)
    end

    private

    attr_reader :many_sentence_parser
end

class SentenceAndEOFParser
    def initialize
        @many_sentence_parser = ParseMany.new(SentenceParser.new)
    end

    def parse(tokens)
        sentences = many_sentence_parser.parse_many(tokens)
        consumed = sentences.map(&:consumed).sum
        remaining = tokens[consumed...]

        next_token = remaining[0]
        next_next_token = remaining[1]
        
        if next_token == :newline && next_next_token == :end_of_file
            ParagraphNode.new(sentences: sentences, consumed: consumed + 2)    
        elsif next_token == :end_of_file
            ParagraphNode.new(sentences: sentences, consumed: consumed + 1)
        else
            nil
        end
    end

    private

    attr_reader :many_sentence_parser
end