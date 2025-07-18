# frozen_string_literal: true

require_relative "element_converter"

module Haml2erb
  # rubocop:todo Style/Documentation
  class LineProcessor # rubocop:disable Metrics/ClassLength, Style/Documentation
    # rubocop:enable Style/Documentation
    def self.process(line, has_children = false) # rubocop:disable Style/OptionalBooleanParameter
      new(line, has_children).process
    end

    def initialize(line, has_children = false) # rubocop:disable Style/OptionalBooleanParameter
      @line = line
      @has_children = has_children
    end

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def process # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      stripped = @line.strip
      indent = @line[/^\s*/]

      return @line if stripped.empty?

      if stripped.start_with?("!!!")
        convert_doctype_line(stripped, indent)
      elsif stripped.start_with?("-#")
        convert_haml_comment_line(stripped, indent)
      elsif stripped.start_with?("%")
        ElementConverter.convert_element(stripped, indent, @has_children)
      elsif stripped.start_with?(".")
        ElementConverter.convert_class(stripped, indent, @has_children)
      elsif stripped.start_with?("#") && !stripped.start_with?('#{')
        ElementConverter.convert_id(stripped, indent, @has_children)
      elsif stripped.start_with?("=")
        convert_ruby_output_line(stripped, indent)
      elsif stripped.start_with?("-")
        convert_ruby_code_line(stripped, indent)
      elsif stripped.start_with?("&=")
        convert_escaped_output_line(stripped, indent)
      elsif stripped.start_with?("!=")
        convert_unescaped_output_line(stripped, indent)
      elsif stripped.start_with?("/")
        convert_comment_line(stripped, indent)
      elsif stripped.start_with?(":")
        convert_filter_line(stripped, indent)
      else
        convert_text_line(stripped, indent)
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    private

    def convert_ruby_output_line(line, indent)
      code = line[1..].strip

      # Check if there's an inline comment (but not inside string literals)
      if code.include?(" #") && !inside_string_literal?(code, code.index(" #"))
        ruby_part, comment_part = code.split(" #", 2)
        processed_code = process_string_interpolations(ruby_part.strip)
        "#{indent}<%= #{processed_code} %> <%# #{comment_part.strip} %>\n"
      else
        processed_code = process_string_interpolations(code)
        "#{indent}<%= #{processed_code} %>\n"
      end
    end

    def convert_ruby_code_line(line, indent)
      code = line[1..].strip
      "#{indent}<% #{code} %>\n"
    end

    def convert_escaped_output_line(line, indent)
      code = line[2..].strip
      "#{indent}<%= #{code} %>\n"
    end

    def convert_unescaped_output_line(line, indent)
      code = line[2..].strip
      "#{indent}<%== #{code} %>\n"
    end

    def convert_comment_line(line, indent)
      comment = line[1..].strip
      "#{indent}<!-- #{comment} -->\n"
    end

    def convert_haml_comment_line(line, indent)
      comment_content = line[2..].strip

      # All HAML comments are converted to ERB comments
      "#{indent}<%# #{comment_content} %>\n"
    end

    def convert_text_line(line, indent)
      # Convert Ruby interpolations #{...} to ERB <%= ... %>
      converted_line = line.gsub(/#\{([^}]+)\}/, '<%= \1 %>')
      # Convert escaped hyphen \- to just -
      converted_line = converted_line.gsub(/\\-/, "-")
      "#{indent}#{converted_line}\n"
    end

    def convert_doctype_line(line, indent)
      if line.strip == "!!!"
        "#{indent}<!DOCTYPE html>\n"
      else
        "#{indent}#{line}\n"
      end
    end

    def convert_filter_line(line, indent)
      filter_type = line[1..].strip

      case filter_type
      when "ruby"
        # This will be handled by FilterProcessor
        { type: :filter_start, filter_type: "ruby", indent: indent.length }
      else
        "#{indent}#{line}\n"
      end
    end

    def process_string_interpolations(code)
      # Simply return the code as-is for Ruby output lines
      # The #{...} interpolation should work normally in ERB
      code
    end

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    def inside_string_literal?(code, position) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      # Check if the position is inside a string literal
      in_string = false
      string_char = nil
      escaped = false

      (0...position).each do |i|
        char = code[i]

        if escaped
          escaped = false
          next
        end

        if char == "\\"
          escaped = true
          next
        end

        if !in_string && ['"', "'"].include?(char)
          in_string = true
          string_char = char
        elsif in_string && char == string_char
          in_string = false
          string_char = nil
        end
      end

      in_string
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
