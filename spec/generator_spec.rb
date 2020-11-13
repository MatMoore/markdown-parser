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
    end
end