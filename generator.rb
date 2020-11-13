class Generator
    def initialize(visitor)
        @visitor = visitor
    end

    def generate(ast)
        visit_body(ast)
    end

private

    attr_reader :visitor

    def visit(method, node)
        visitor.send(method, node) if visitor.respond_to?(method)
    end

    def visit_body(node)
        visit(:enter_body, node)

        node.paragraphs.each do |paragraph|
            visit_paragraph(paragraph)
        end

        visit(:exit_body, node)
    end

    def visit_paragraph(node)
        visit(:enter_paragraph, node)

        node.sentences.each do |sentence|
            case sentence
            when EmphasisedTextNode
                visit_emphasised(sentence)
            when BoldTextNode
                visit_bold(sentence)
            when TextNode
                visit_text(sentence)
            end
        end

        visit(:exit_paragraph, node)
    end

    def visit_emphasised(node)
        visit(:visit_emphasised, node)
    end

    def visit_text(node)
        visit(:visit_text, node)
    end

    def visit_bold(node)
        visit(:visit_bold, node)
    end
end

class ConsoleOutput
    def initialize(stream)
        @stream = stream
    end

    def visit_text(node)
         stream.puts node.value
    end

    private
    attr_reader :stream
end