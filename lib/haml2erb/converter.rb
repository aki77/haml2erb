# frozen_string_literal: true

require_relative "block_stack_manager"
require_relative "filter_processor"
require_relative "line_processor"

module Haml2erb
  # rubocop:todo Style/Documentation
  class Converter # rubocop:todo Metrics/ClassLength, Style/Documentation
    # rubocop:enable Style/Documentation
    def initialize(haml_content)
      @haml_content = haml_content
      @block_stack_manager = BlockStackManager.new
      @filter_processor = FilterProcessor.new
    end

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def convert # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      lines = @haml_content.lines
      processed_lines = merge_multiline_statements(lines)
      erb_lines = []

      processed_lines.each_with_index do |line, index|
        current_indent = line[/^\s*/].length
        next_line = processed_lines[index + 1]
        next_indent = next_line ? next_line[/^\s*/].length : 0

        # Handle filter content
        next if @filter_processor.active? && @filter_processor.process_filter_content(line, current_indent, erb_lines)

        # Skip block closing logic for empty lines
        if line.strip.empty?
          erb_lines << line
          next
        end

        # Handle else/elsif special case and close blocks
        is_else_elsif = @block_stack_manager.is_else_or_elsif?(line)
        @block_stack_manager.close_blocks_for_indent(current_indent, erb_lines, is_else_elsif: is_else_elsif)

        result = process_line(line, next_indent > current_indent)

        # Handle filter start
        if result.is_a?(Hash) && result[:type] == :filter_start
          filter_result = @filter_processor.start_filter(result[:filter_type], result[:indent])
          erb_lines << filter_result if filter_result
        elsif result && !result.empty?
          erb_lines << result
        end

        # Track blocks and elements that need closing
        @block_stack_manager.track_block_for_line(line, current_indent, next_indent)
      end

      # Close any remaining filter
      @filter_processor.close_filter(erb_lines)

      # Close any remaining blocks/elements
      @block_stack_manager.close_all_blocks(erb_lines)

      erb_lines.join
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    private

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def merge_multiline_statements(lines) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      result = []
      i = 0

      while i < lines.length
        line = lines[i]

        # Check for multiline attribute block
        if line.strip.match(/^(\.[a-zA-Z_-][a-zA-Z0-9_-]*|%[a-zA-Z0-9_-]+.*?)\{\s*$/)
          merged_line = merge_multiline_attributes(lines, i)
          if merged_line
            result << "#{merged_line[:line]}\n"
            i = merged_line[:next_index]
            next
          end
        end

        # Ruby output lines (starting with =) ending with comma may span multiple lines
        if line.strip.start_with?("=") && line.strip.end_with?(",")
          merged_line = line.chomp
          base_indent = line[/^\s*/]
          i += 1

          # Search for continuation lines from the next line
          while i < lines.length
            next_line = lines[i]
            next_stripped = next_line.strip
            next_indent = next_line[/^\s*/]

            # Skip empty lines
            if next_stripped.empty? # rubocop:todo Metrics/BlockNesting
              i += 1
              next
            end

            # If it's a deeper indented continuation line
            break unless next_indent.length > base_indent.length

            # Join with space (preserving commas)
            merged_line += " #{next_stripped}"
            i += 1

            # End when indentation becomes shallower

          end

          result << "#{merged_line}\n"
        else
          result << line
          i += 1
        end
      end

      result
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    def merge_multiline_attributes(lines, start_index) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      line = lines[start_index]
      base_indent = line[/^\s*/]

      # Extract element part and opening brace
      if (match = line.strip.match(/^(.+?)\{\s*$/))
        element_part = match[1]
        merged_attrs = []
        i = start_index + 1

        # Collect attribute lines until closing brace
        while i < lines.length
          attr_line = lines[i]
          attr_stripped = attr_line.strip
          attr_indent = attr_line[/^\s*/]

          # Skip empty lines
          if attr_stripped.empty?
            i += 1
            next
          end

          # Found closing brace
          if attr_stripped == "}"
            # Look for content after closing brace
            content_i = i + 1
            content_lines = []
            content_base_indent = nil

            while content_i < lines.length # rubocop:todo Metrics/BlockNesting
              content_line = lines[content_i]
              content_stripped = content_line.strip
              content_indent = content_line[/^\s*/]

              # Skip empty lines
              if content_stripped.empty? # rubocop:todo Metrics/BlockNesting
                content_i += 1
                next
              end

              # Set base content indent from first non-empty line
              # rubocop:todo Metrics/BlockNesting
              content_base_indent = content_indent.length if content_base_indent.nil?
              # rubocop:enable Metrics/BlockNesting

              # If indent matches content level, it's part of content
              break unless content_indent.length == content_base_indent # rubocop:todo Metrics/BlockNesting

              content_lines << content_stripped
              content_i += 1

            end

            # Build merged line
            merged_line = "#{base_indent}#{element_part}{ #{merged_attrs.join(", ")} }"
            merged_line += " #{content_lines.join(" ")}" unless content_lines.empty?

            return { line: merged_line, next_index: content_i }
          end

          # Attribute line
          break unless attr_indent.length > base_indent.length

          # Remove trailing comma if present
          attr_content = attr_stripped.sub(/,\s*$/, "")
          merged_attrs << attr_content unless attr_content.empty?
          i += 1

          # Indent decreased, end of attribute block

        end
      end

      nil
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    def process_line(line, has_children = false) # rubocop:disable Style/OptionalBooleanParameter
      LineProcessor.process(line, has_children)
    end
  end
end
