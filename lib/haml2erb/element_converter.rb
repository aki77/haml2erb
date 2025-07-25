# rubocop:disable Style/OptionalBooleanParameter
# frozen_string_literal: true

require_relative "attribute_parser"
require_relative "tag_parser"
require_relative "tag_builder"
require_relative "string_utils"

module Haml2erb
  class ElementConverter # rubocop:todo Style/Documentation
    def self.convert_element(line, indent, has_children = false)
      new(line, indent, has_children).convert
    end

    def self.convert_class(line, indent, has_children = false)
      new(line, indent, has_children).convert_class
    end

    def self.convert_id(line, indent, has_children = false)
      new(line, indent, has_children).convert_id
    end

    def initialize(line, indent, has_children = false)
      @line = line
      @indent = indent
      @has_children = has_children
    end

    def convert
      # Only return as-is if the line starts with ERB tag, not if ERB is inside attributes
      return "#{@indent}#{@line}\n" if @line.strip.start_with?("<%")

      tag_info = TagParser.parse(@line)
      return "#{@indent}#{@line}\n" unless tag_info

      TagBuilder.build(tag_info, @indent, @has_children)
    end

    def convert_class
      tag_info = TagParser.parse(@line)
      return "#{@indent}#{@line}\n" unless tag_info

      TagBuilder.build(tag_info, @indent, @has_children)
    end

    def convert_id
      tag_info = TagParser.parse(@line)
      return "#{@indent}#{@line}\n" unless tag_info

      TagBuilder.build(tag_info, @indent, @has_children)
    end
  end
end
# rubocop:enable Style/OptionalBooleanParameter
