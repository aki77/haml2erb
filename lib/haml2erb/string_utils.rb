# frozen_string_literal: true

module Haml2erb
  # Common string utility methods
  module StringUtils
    module_function

    # Convert Ruby string interpolation #{...} to ERB output <%= ... %>
    def process_interpolation(content)
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

    # Extract balanced braces from text
    # Returns { content: "...", remaining: "..." } or nil
    def extract_balanced_braces(text)
      text = text.strip
      return nil unless text.start_with?("{")

      result = find_closing_delimiter(text, "{", "}")
      return nil unless result

      {
        content: text[1...result[:position]],
        remaining: text[(result[:position] + 1)..]
      }
    end

    # Find the position of closing delimiter considering quotes and nesting
    # Returns { position: index } or nil
    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def find_closing_delimiter(text, open_delim, close_delim) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      delimiter_count = 0
      in_quote = false
      quote_char = nil
      i = 0

      while i < text.length
        char = text[i]

        if !in_quote && ['"', "'"].include?(char)
          in_quote = true
          quote_char = char
        elsif in_quote && char == quote_char && (i.zero? || text[i - 1] != "\\")
          in_quote = false
          quote_char = nil
        elsif !in_quote
          if char == open_delim
            delimiter_count += 1
          elsif char == close_delim
            delimiter_count -= 1
            return { position: i } if delimiter_count.zero?
          end
        end

        i += 1
      end

      nil
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    # Split string by delimiter considering quotes and parentheses
    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def smart_split(text, delimiter = ",") # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      result = []
      current_part = ""
      in_quote = false
      quote_char = nil
      paren_depth = 0
      i = 0

      while i < text.length
        char = text[i]

        if !in_quote && ['"', "'"].include?(char)
          in_quote = true
          quote_char = char
          current_part += char
        elsif in_quote && char == quote_char && (i.zero? || text[i - 1] != "\\")
          in_quote = false
          quote_char = nil
          current_part += char
        elsif !in_quote && char == "("
          paren_depth += 1
          current_part += char
        elsif !in_quote && char == ")"
          paren_depth -= 1
          current_part += char
        elsif !in_quote && paren_depth.zero? && char == delimiter
          result << current_part
          current_part = ""
        else
          current_part += char
        end

        i += 1
      end

      result << current_part unless current_part.empty?
      result
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
