require_relative "parser"
require_relative "generator"

markdown = STDIN.read
ast = Parser.new.parse(markdown)
generator = Generator.new(ConsoleOutput.new)

generator.generate(ast)