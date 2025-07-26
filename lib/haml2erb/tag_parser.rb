# frozen_string_literal: true

require_relative "string_utils"

module Haml2erb
  # Parses HAML element tags and extracts components
  class TagParser # rubocop:todo Metrics/ClassLength
    # Data structure to hold parsed tag information
    TagInfo = Struct.new(:tag_name, :classes, :ids, :attributes_hash, :content, :has_ruby_code) do
      def initialize(*)
        super
        self.classes ||= []
        self.ids ||= []
        self.attributes_hash ||= nil
        self.content ||= ""
        self.has_ruby_code ||= false
      end
    end

    def self.parse(line)
      new(line).parse
    end

    def initialize(line)
      @line = line.strip
    end

    def parse
      return nil unless element_line?

      if @line.start_with?("%")
        parse_element_tag
      elsif @line.start_with?(".")
        parse_class_shorthand
      elsif @line.start_with?("#")
        parse_id_shorthand
      end
    end

    private

    def element_line?
      @line.match?(/^[%#.]/)
    end

    # rubocop:todo Metrics/MethodLength
    def parse_element_tag # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      match = @line.match(/^%([a-zA-Z0-9_-]+)(.*)$/)
      return nil unless match

      tag_info = TagInfo.new
      tag_info.tag_name = match[1]
      remaining = match[2]

      # Parse classes and IDs
      remaining = parse_class_id_spec(remaining, tag_info) if remaining.start_with?(".") || remaining.start_with?("#")

      # Parse attributes hash
      if remaining.strip.start_with?("{")
        result = StringUtils.extract_balanced_braces(remaining.strip)
        if result
          tag_info.attributes_hash = result[:content]
          remaining = result[:remaining]
        end
      end

      # Parse content
      parse_content(remaining.strip, tag_info)

      tag_info
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:todo Metrics/MethodLength
    def parse_class_shorthand # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      tag_info = TagInfo.new
      tag_info.tag_name = "div"
      remaining = @line

      # Parse .class1.class2{attrs} content
      if (match = remaining.match(/^([.#][.#:a-zA-Z0-9_-]+)(.*)$/))
        remaining = parse_class_id_spec(match[1], tag_info)
        remaining += match[2]
      end

      # Parse attributes hash
      if remaining.strip.start_with?("{")
        result = StringUtils.extract_balanced_braces(remaining.strip)
        if result
          tag_info.attributes_hash = result[:content]
          remaining = result[:remaining]
        end
      end

      parse_content(remaining.strip, tag_info)
      tag_info
    end
    # rubocop:enable Metrics/MethodLength

    def parse_id_shorthand
      tag_info = TagInfo.new
      tag_info.tag_name = "div"

      match = @line.match(/^#([a-zA-Z0-9_-]+)(.*)$/)
      return nil unless match

      tag_info.ids << match[1]
      remaining = match[2]

      parse_content(remaining.strip, tag_info)
      tag_info
    end

    def parse_class_id_spec(spec, tag_info) # rubocop:todo Metrics/MethodLength
      remaining = ""
      current_spec = spec

      # Find where the class/id spec ends
      if (match = current_spec.match(/^([.#:a-zA-Z0-9_.-]+)(.*)$/))
        class_id_part = match[1]
        remaining = match[2]

        # Split into individual classes and IDs
        parts = class_id_part.split(/(?=[.#])/)
        parts.each do |part|
          next if part.empty?

          if part.start_with?(".")
            tag_info.classes << part[1..]
          elsif part.start_with?("#")
            tag_info.ids << part[1..]
          end
        end
      end

      remaining
    end

    def parse_content(content, tag_info)
      return if content.empty?

      if content.start_with?("=")
        tag_info.has_ruby_code = true
        tag_info.content = content[1..].strip
      else
        tag_info.content = content
      end
    end
  end
end
