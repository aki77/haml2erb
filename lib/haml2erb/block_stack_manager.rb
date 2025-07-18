# frozen_string_literal: true

module Haml2erb
  class BlockStackManager # rubocop:todo Style/Documentation
    def initialize
      @stack = []
    end

    def close_blocks_for_indent(current_indent, erb_lines, is_else_elsif: false) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      if is_else_elsif
        # Close blocks at the same indent level as else/elsif but not the if block itself
        while @stack.any? && current_indent < @stack.last[:indent]
          closed_block = @stack.pop
          erb_lines << "#{" " * closed_block[:indent]}#{closed_block[:close_tag]}\n"
        end
      else
        # Normal block closing
        while @stack.any? && current_indent <= @stack.last[:indent]
          closed_block = @stack.pop
          erb_lines << "#{" " * closed_block[:indent]}#{closed_block[:close_tag]}\n"
        end
      end
    end

    def track_block_for_line(line, current_indent, next_indent) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      stripped = line.strip

      if stripped.start_with?("=") && stripped.include?(" do")
        @stack << { indent: current_indent, close_tag: "<% end %>" }
      elsif stripped.start_with?("-") && next_indent > current_indent
        # Check if this is an else/elsif statement
        ruby_code = stripped[1..].strip
        if !(ruby_code.start_with?("else") || ruby_code.start_with?("elsif")) && creates_block?(ruby_code)
          # Only add end tag for Ruby code that actually creates blocks
          # Exclude simple method calls like breadcrumb :test
          @stack << { indent: current_indent, close_tag: "<% end %>" }
        end
      elsif stripped.start_with?("%") && next_indent > current_indent
        tag_match = stripped.match(/^%([a-zA-Z0-9_-]+)/)
        if tag_match
          tag = tag_match[1]
          @stack << { indent: current_indent, close_tag: "</#{tag}>" }
        end
      elsif stripped.start_with?(".") && next_indent > current_indent
        @stack << { indent: current_indent, close_tag: "</div>" }
      elsif stripped.start_with?("#") && next_indent > current_indent
        @stack << { indent: current_indent, close_tag: "</div>" }
      end
    end

    def close_all_blocks(erb_lines)
      while @stack.any?
        closed_block = @stack.pop
        erb_lines << "#{" " * closed_block[:indent]}#{closed_block[:close_tag]}\n"
      end
    end

    def empty?
      @stack.empty?
    end

    def any?
      @stack.any?
    end

    def is_else_or_elsif?(line) # rubocop:todo Naming/PredicatePrefix
      return false unless line.strip.start_with?("-")

      ruby_code = line.strip[1..].strip
      ruby_code.start_with?("else") || ruby_code.start_with?("elsif")
    end

    private

    def creates_block?(ruby_code)
      # Check if the Ruby code creates a block that needs an end statement
      block_keywords = %w[if unless case while until for begin]
      # Check for block keywords at the start of the statement
      return true if block_keywords.any? { |keyword| ruby_code.start_with?("#{keyword} ") || ruby_code == keyword }

      # Check for method calls with do blocks
      ruby_code.include?(" do ")
    end
  end
end
