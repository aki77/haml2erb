# rubocop:disable Style/OptionalBooleanParameter
# frozen_string_literal: true

require_relative "attribute_parser"

module Haml2erb
  class ElementConverter # rubocop:todo Metrics/ClassLength, Style/Documentation
    # HTML5 void elements (self-closing tags)
    VOID_ELEMENTS = %w[
      area base br col embed hr img input link meta
      param source track wbr
    ].freeze
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

    def convert # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      return "#{@indent}#{@line}\n" if @line.include?("<%")

      match = @line.match(/^%([a-zA-Z0-9_-]+)(.*)$/)
      return "#{@indent}#{@line}\n" unless match

      tag = match[1]
      rest = match[2]

      attributes = ""
      content = ""

      # Handle CSS classes and IDs in element tag
      if rest.start_with?(".") || rest.start_with?("#")
        class_id_match = rest.match(/^([.#:a-zA-Z0-9_.-]+)(.*)$/)
        if class_id_match
          class_id_spec = class_id_match[1]
          remaining = class_id_match[2]

          # Parse classes and IDs
          classes = []
          ids = []

          # Handle complex class specs like .hidden.lg:block.font-normal.text-xs
          parts = class_id_spec.split(/(?=[.#])/)
          parts.each do |part|
            if part.start_with?(".")
              class_name = part[1..]
              classes << class_name
            elsif part.start_with?("#")
              ids << part[1..]
            end
          end

          attr_parts = []
          attr_parts << "class=\"#{classes.join(" ")}\"" unless classes.empty?
          attr_parts << "id=\"#{ids.join(" ")}\"" unless ids.empty?
          attributes = " #{attr_parts.join(" ")}" unless attr_parts.empty?

          rest = remaining
        end
      end

      # HAML attributes need to come early in the line (e.g., %div{class: "test"} content)
      # To distinguish from string interpolation #{...}, look for { closer to spaces
      if rest.strip.start_with?("{") || rest.match(/^\s*\{/)
        attr_content = extract_balanced_braces(rest)
        if attr_content
          additional_attributes = AttributeParser.parse(attr_content[:attributes])

          # Check if additional attributes contain class, merge with existing classes
          if additional_attributes.include?("class=") && attributes.include?("class=")
            # Extract existing classes
            existing_class = attributes.match(/class="([^"]*)"/)
            additional_class = additional_attributes.match(/class="([^"]*)"/)

            if existing_class && additional_class # rubocop:todo Metrics/BlockNesting
              merged_classes = "#{existing_class[1]} #{additional_class[1]}"
              attributes = attributes.gsub(/class="[^"]*"/, "class=\"#{merged_classes}\"")
              additional_attributes = additional_attributes.gsub(/\s*class="[^"]*"/, "")
            end
          end

          attributes += additional_attributes
          content = attr_content[:remaining].strip
        else
          content = rest.strip
        end
      else
        content = rest.strip
      end

      # Check if this is a void element (self-closing tag)
      if VOID_ELEMENTS.include?(tag)
        "#{@indent}<#{tag}#{attributes}>\n"
      elsif content.empty? && !@has_children
        "#{@indent}<#{tag}#{attributes}></#{tag}>\n"
      elsif @has_children
        "#{@indent}<#{tag}#{attributes}>\n"
      elsif content.empty?
        "#{@indent}<#{tag}#{attributes}></#{tag}>\n"
      elsif content.start_with?("=")
        ruby_code = content[1..].strip
        "#{@indent}<#{tag}#{attributes}><%= #{ruby_code} %></#{tag}>\n"
      else
        processed_content = process_interpolation(content)
        "#{@indent}<#{tag}#{attributes}>#{processed_content}</#{tag}>\n"
      end
    end

    def convert_class # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      rest = @line[1..]

      # Handle attributes in hash format
      if rest.include?("{")
        attr_match = rest.match(/^([^{]*)\{([^}]*)\}(.*)/)
        if attr_match
          class_spec = attr_match[1]
          attributes_str = attr_match[2]
          content = attr_match[3].strip

          # Convert .class1.class2.class3 to separate classes
          classes = class_spec.split(".").reject(&:empty?)

          # Parse additional attributes and handle class merging
          additional_attributes = AttributeParser.parse(attributes_str)

          # Check if additional_attributes contains class attribute
          if additional_attributes.include?("class=")
            # Extract class value from additional_attributes
            class_match = additional_attributes.match(/class="([^"]*)"/)
            if class_match # rubocop:todo Metrics/BlockNesting
              additional_class = class_match[1]
              classes << additional_class
              # Remove class attribute from additional_attributes
              additional_attributes = additional_attributes.gsub(/\s*class="[^"]*"/, "")
            end
          end

          class_attr = classes.join(" ")
          all_attributes = " class=\"#{class_attr}\"#{additional_attributes}"

          if content && !content.empty? && !@has_children
            processed_content = process_interpolation(content)
            "#{@indent}<div#{all_attributes}>#{processed_content}</div>\n"
          elsif !@has_children
            "#{@indent}<div#{all_attributes}></div>\n"
          else
            "#{@indent}<div#{all_attributes}>\n"
          end
        else
          # Fallback to original logic
          parts = rest.split(" ", 2)
          class_spec = parts[0]
          content = parts[1]

          classes = class_spec.split(".").reject(&:empty?)
          class_attr = classes.join(" ")

          if content && !content.empty? && !@has_children
            processed_content = process_interpolation(content)
            "#{@indent}<div class=\"#{class_attr}\">#{processed_content}</div>\n"
          else
            "#{@indent}<div class=\"#{class_attr}\">\n"
          end
        end
      else
        parts = rest.split(" ", 2)
        class_spec = parts[0]
        content = parts[1]

        # Convert .class1.class2.class3 to separate classes
        classes = class_spec.split(".").reject(&:empty?)
        class_attr = classes.join(" ")

        if content && !content.empty? && !@has_children
          processed_content = process_interpolation(content)
          "#{@indent}<div class=\"#{class_attr}\">#{processed_content}</div>\n"
        else
          "#{@indent}<div class=\"#{class_attr}\">\n"
        end
      end
    end

    def convert_id
      rest = @line[1..]
      parts = rest.split(" ", 2)
      id_name = parts[0]
      content = parts[1]

      if content && !content.empty? && !@has_children
        processed_content = process_interpolation(content)
        "#{@indent}<div id=\"#{id_name}\">#{processed_content}</div>\n"
      else
        "#{@indent}<div id=\"#{id_name}\">\n"
      end
    end

    private

    def extract_balanced_braces(text) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      text = text.strip
      return nil unless text.start_with?("{")

      brace_count = 0
      in_quote = false
      quote_char = nil
      i = 0

      while i < text.length
        char = text[i]

        if !in_quote && ['"', "'"].include?(char)
          in_quote = true
          quote_char = char
        elsif in_quote && char == quote_char
          in_quote = false
          quote_char = nil
        elsif !in_quote
          if char == "{"
            brace_count += 1
          elsif char == "}"
            brace_count -= 1
            if brace_count.zero? # rubocop:todo Metrics/BlockNesting
              attributes = text[1...i]
              remaining = text[(i + 1)..]
              return { attributes: attributes, remaining: remaining }
            end
          end
        end

        i += 1
      end

      nil
    end

    def process_interpolation(content)
      # Convert Ruby string interpolation #{...} to ERB output <%= ... %>
      content.gsub(/\\?\#{([^}]+)}/) do |match|
        if match.start_with?("\\")
          # Return as-is if escaped
          match[1..]
        else
          # Convert Ruby interpolation to ERB output
          ruby_code = ::Regexp.last_match(1)
          "<%= #{ruby_code} %>"
        end
      end
    end
  end
end
# rubocop:enable Style/OptionalBooleanParameter
