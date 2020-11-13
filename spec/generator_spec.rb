# frozen_string_literal: true

require 'rspec'
require_relative '../parser'
require_relative '../generator'

RSpec.describe(Generator) do
    context "with a dummy visitor" do
        let(:visitor) { spy(:visitor) }
        subject(:generator) { Generator.new(visitor) }

        it "calls the visit methods in the right order" do
            text = TextNode.new(value: "hello world")
            paragraph = ParagraphNode.new(sentences: [text])
            ast = BodyNode.new(paragraphs: [paragraph])     

            generator.generate(ast)

            expect(visitor).to have_received(:enter_body).ordered
            expect(visitor).to have_received(:enter_paragraph).ordered
            expect(visitor).to have_received(:visit_text).ordered
            expect(visitor).to have_received(:exit_paragraph).ordered
            expect(visitor).to have_received(:exit_body).ordered
        end
    end

    context "with console output" do
        let(:stream) { StringIO.new }
        let(:visitor) { ConsoleOutput.new(stream) }
        subject(:generator) { Generator.new(visitor) }

        it "generates plain text" do
            text = TextNode.new(value: "hello world")
            paragraph = ParagraphNode.new(sentences: [text])
            ast = BodyNode.new(paragraphs: [paragraph])     

            generator.generate(ast)

            expect(stream.string).to eq("hello world\n")
        end

        it "handles paragraph breaks" do
            hello = TextNode.new(value: "hello")
            world = TextNode.new(value: "world")
            paragraph = ParagraphNode.new(sentences: [hello])
            another_paragraph = ParagraphNode.new(sentences: [world])
            ast = BodyNode.new(paragraphs: [paragraph, another_paragraph])     

            generator.generate(ast)

            expect(stream.string).to eq("hello\n\nworld\n")
        end

        it "handles bold text" do
            hello = BoldTextNode.new(value: "hello")
            world = TextNode.new(value: " world")
            paragraph = ParagraphNode.new(sentences: [hello, world])
            ast = BodyNode.new(paragraphs: [paragraph])     

            generator.generate(ast)

            expect(stream.string).to eq("\u001b[1mhello\u001b[0m world\n")
        end

        it "handles emphasised text" do
            hello = TextNode.new(value: "hello ")
            world = EmphasisedTextNode.new(value: "world")
            paragraph = ParagraphNode.new(sentences: [hello, world])
            ast = BodyNode.new(paragraphs: [paragraph])     

            generator.generate(ast)

            expect(stream.string).to eq("hello \u001b[7mworld\u001b[0m\n")
        end
    end
end