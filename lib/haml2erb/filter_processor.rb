# frozen_string_literal: true

module Haml2erb
  class FilterProcessor # rubocop:todo Style/Documentation
    def initialize
      @current_filter = nil
    end

    def start_filter(filter_type, indent)
      case filter_type
      when "ruby"
        @current_filter = { indent: indent, type: "ruby" }
        "#{" " * indent}<%\n"
      end
    end

    def process_filter_content(line, current_indent, erb_lines)
      return false unless @current_filter

      if current_indent <= @current_filter[:indent]
        # Close filter
        erb_lines << "#{" " * @current_filter[:indent]}%>\n"
        @current_filter = nil
        false
      else
        # Filter content - use the line as-is (already has newline)
        erb_lines << line
        true
      end
    end

    def close_filter(erb_lines)
      return unless @current_filter

      erb_lines << "#{" " * @current_filter[:indent]}%>\n"
      @current_filter = nil
    end

    def active?
      !@current_filter.nil?
    end
  end
end
