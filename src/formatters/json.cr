require "json"
require "json/pull_parser"
require "colorize"

module Crul
  module Formatters
    class JSON < Base
      def print
        begin
          printer = PrettyPrinter.new(@response.body, @output)
          printer.print
          @output.puts
        rescue ::JSON::ParseException
          print_plain
        end
      end

      # taken almost verbatim from https://github.com/crystal-lang/crystal/blob/257eaa23b40bb4abef2f82029697c2785b9cb588/samples/pretty_json.cr
      # needed changes:
      #  * @input is IO | String instead of IO
      #  * JSON constant needs to be “rooted” (::JSON)
      class PrettyPrinter
        def initialize(@input : IO | String, @output : IO)
          @pull = ::JSON::PullParser.new @input
          @indent = 0
        end

        def print
          read_any
        end

        def read_any
          case @pull.kind
          when .null?
            with_color.bold.surround(@output) do
              @pull.read_null.to_json(@output)
            end
          when .bool?
            with_color.light_blue.surround(@output) do
              @pull.read_bool.to_json(@output)
            end
          when .int?
            with_color.red.surround(@output) do
              @pull.read_int.to_json(@output)
            end
          when .float?
            with_color.red.surround(@output) do
              @pull.read_float.to_json(@output)
            end
          when .string?
            with_color.yellow.surround(@output) do
              @pull.read_string.to_json(@output)
            end
          when .begin_array?
            read_array
          when .begin_object?
            read_object
          when .eof?
            # We are done
          else
            raise "Bug: unexpected kind: #{@pull.kind}"
          end
        end

        def read_array
          print "[\n"
          @indent += 1
          i = 0
          @pull.read_array do
            if i > 0
              print ','
              print '\n' if @indent > 0
            end
            print_indent
            read_any
            i += 1
          end
          @indent -= 1
          print '\n'
          print_indent
          print ']'
        end

        def read_object
          print "{\n"
          @indent += 1
          i = 0
          @pull.read_object do |key|
            if i > 0
              print ','
              print '\n' if @indent > 0
            end
            print_indent
            with_color.cyan.surround(@output) do
              key.to_json(@output)
            end
            print ": "
            read_any
            i += 1
          end
          @indent -= 1
          print '\n'
          print_indent
          print '}'
        end

        def print_indent
          @indent.times { @output << "  " }
        end

        def print(value)
          @output << value
        end
      end
    end
  end
end
