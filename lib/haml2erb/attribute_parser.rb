# frozen_string_literal: true

module Haml2erb
  # Parses HAML attributes and converts them to HTML
  class AttributeParser # rubocop:todo Metrics/ClassLength
    def self.parse(attr_string)
      new(attr_string).parse
    end

    def initialize(attr_string)
      @attr_string = attr_string
    end

    def parse
      return "" if @attr_string.empty?

      attrs = []
      smart_split_attributes(@attr_string).each do |attr|
        processed_attr = process_attribute(attr.strip)
        attrs << processed_attr if processed_attr
      end
      attrs.join
    end

    private

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def smart_split_attributes(attr_string) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      result = []
      current_attr = ""
      in_quote = false
      quote_char = nil
      i = 0

      while i < attr_string.length
        char = attr_string[i]

        if !in_quote && ['"', "'"].include?(char)
          in_quote = true
          quote_char = char
          current_attr += char
        elsif in_quote && char == quote_char
          in_quote = false
          quote_char = nil
          current_attr += char
        elsif !in_quote && char == ","
          result << current_attr
          current_attr = ""
        else
          current_attr += char
        end

        i += 1
      end

      result << current_attr unless current_attr.empty?
      result
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def process_attribute(attr) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      return nil if attr.empty?

      # Handle nested hash attributes like data: { test_id: 'test' }
      if (match = extract_nested_hash_attribute(attr))
        parse_nested_hash(match)
      elsif (match = attr.match(/:([a-zA-Z_][a-zA-Z0-9_-]*)\s*=>\s*(['"])(.*?)\2/))
        parse_old_format_string(match)
      elsif (match = attr.match(/:([a-zA-Z_][a-zA-Z0-9_-]*)\s*=>\s*(\d+)/))
        parse_old_format_numeric(match)
      elsif (match = attr.match(/(['"])([a-zA-Z_-][a-zA-Z0-9_-]*)\1\s*:\s*(['"])(.*?)\3/))
        parse_new_format_quoted(match)
      elsif (match = attr.match(/(['"])([a-zA-Z_-][a-zA-Z0-9_-]*)\1\s*:\s*(true|false)/))
        parse_new_format_boolean(match)
      elsif (match = attr.match(/(['"])([a-zA-Z_-][a-zA-Z0-9_-]*)\1\s*:\s*([a-zA-Z_][a-zA-Z0-9_.:()]+)/))
        parse_new_format_code(match)
      elsif (match = attr.match(/([a-zA-Z_-][a-zA-Z0-9_-]*)\s*:\s*(['"])(.*?)\2/))
        parse_symbol_quoted(match)
      elsif (match = attr.match(/([a-zA-Z_-][a-zA-Z0-9_-]*)\s*:\s*(true|false)/))
        parse_symbol_boolean(match)
      elsif (match = attr.match(/([a-zA-Z_-][a-zA-Z0-9_-]*)\s*:\s*([a-zA-Z_@:][a-zA-Z0-9_.()@:\[\]&]+)/))
        parse_symbol_code(match)
      elsif (match = attr.match(/([a-zA-Z_-][a-zA-Z0-9_-]*)\s*:\s*(\d+)/))
        parse_symbol_numeric(match)
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    def parse_old_format_string(match)
      key, _, value = match.captures
      format_attribute(key, value)
    end

    def parse_old_format_numeric(match)
      key, value = match.captures
      " #{key}=\"#{value}\""
    end

    def parse_new_format_quoted(match)
      _, key, _, value = match.captures
      " #{normalize_key(key)}=\"#{value}\""
    end

    def parse_new_format_boolean(match)
      _, key, value = match.captures
      # HTML boolean attributes: if true, output attribute name only; if false, omit attribute
      if value == "true"
        " #{normalize_key(key)}"
      else
        ""
      end
    end

    def parse_new_format_code(match)
      _, key, value = match.captures
      " #{normalize_key(key)}=\"<%= #{value} %>\""
    end

    def parse_symbol_quoted(match)
      key, _, value = match.captures
      " #{normalize_key(key)}=\"#{value}\""
    end

    def parse_symbol_code(match)
      key, value = match.captures
      " #{normalize_key(key)}=\"<%= #{value} %>\""
    end

    def parse_symbol_numeric(match)
      key, value = match.captures
      " #{key}=\"#{value}\""
    end

    def parse_symbol_boolean(match)
      key, value = match.captures
      # HTML boolean attributes: if true, output attribute name only; if false, omit attribute
      if value == "true"
        " #{key}"
      else
        ""
      end
    end

    def format_attribute(key, value)
      " #{key}=\"#{value}\""
    end

    # rubocop:todo Metrics/MethodLength
    def parse_nested_hash(match) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      if match.is_a?(Array)
        _, prefix, nested_attrs = match
      else
        prefix, nested_attrs = match.captures
      end

      # Parse nested attributes
      attrs = []
      smart_split_attributes(nested_attrs).each do |nested_attr|
        nested_attr = nested_attr.strip
        next if nested_attr.empty?

        nested_match = nested_attr.match(/([a-zA-Z_-][a-zA-Z0-9_-]*)\s*:\s*(['"])(.*?)\2/)
        next unless nested_match

        nested_key, _, nested_value = nested_match.captures
        full_key = "#{prefix}-#{normalize_key(nested_key)}"

        # Convert Ruby interpolation #{} to ERB format
        processed_value = convert_ruby_interpolation(nested_value)
        attrs << " #{full_key}=\"#{processed_value}\""
      end

      attrs.join
    end
    # rubocop:enable Metrics/MethodLength

    def normalize_key(key)
      key.include?("_") ? key.gsub("_", "-") : key
    end

    def convert_ruby_interpolation(value)
      # Convert Ruby interpolation #{} to ERB format <%= %>
      value.gsub(/\#\{([^}]+)\}/, '<%= \1 %>')
    end

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def extract_nested_hash_attribute(attr) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      # Match pattern: key: { ... }
      match = attr.match(/([a-zA-Z_-][a-zA-Z0-9_-]*)\s*:\s*\{/)
      return nil unless match

      key = match[1]
      start_pos = match.end(0) - 1 # Position of opening brace

      # Find the matching closing brace, considering nested braces and strings
      brace_count = 0
      in_string = false
      string_char = nil
      i = start_pos

      while i < attr.length
        char = attr[i]

        if !in_string
          if ['"', "'"].include?(char)
            in_string = true
            string_char = char
          elsif char == "{"
            brace_count += 1
          elsif char == "}"
            brace_count -= 1
            if brace_count.zero? # rubocop:todo Metrics/BlockNesting
              # Found the matching closing brace
              content = attr[start_pos + 1...i].strip
              return [attr, key, content]
            end
          end
        elsif char == string_char && (i.zero? || attr[i - 1] != "\\")
          in_string = false
          string_char = nil
        end

        i += 1
      end

      nil
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
