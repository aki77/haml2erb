# frozen_string_literal: true

require_relative "string_utils"
require_relative "attribute_parser"

module Haml2erb
  # Builds HTML tags from parsed tag information
  class TagBuilder
    # HTML5 void elements (self-closing tags)
    VOID_ELEMENTS = %w[
      area base br col embed hr img input link meta
      param source track wbr
    ].freeze
    def self.build(tag_info, indent, has_children)
      new(tag_info, indent, has_children).build
    end

    def initialize(tag_info, indent, has_children)
      @tag_info = tag_info
      @indent = indent
      @has_children = has_children
    end

    def build # rubocop:todo Metrics/MethodLength
      attributes = build_attributes
      tag_name = @tag_info.tag_name

      if void_element?(tag_name)
        build_void_element(tag_name, attributes)
      elsif @tag_info.has_ruby_code
        build_element_with_ruby(tag_name, attributes)
      elsif @tag_info.content.empty?
        build_empty_element(tag_name, attributes)
      else
        build_element_with_content(tag_name, attributes)
      end
    end

    private

    def void_element?(tag_name)
      VOID_ELEMENTS.include?(tag_name)
    end

    def build_attributes
      attrs = []

      # Add classes
      attrs << "class=\"#{@tag_info.classes.join(" ")}\"" unless @tag_info.classes.empty?

      # Add IDs
      attrs << "id=\"#{@tag_info.ids.join(" ")}\"" unless @tag_info.ids.empty?

      # Parse and add hash attributes
      if @tag_info.attributes_hash
        hash_attrs = AttributeParser.parse(@tag_info.attributes_hash)
        attrs = merge_attributes(attrs, hash_attrs)
      end

      attrs.empty? ? "" : " #{attrs.join(" ")}"
    end

    def merge_attributes(base_attrs, additional_attrs) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      return base_attrs if additional_attrs.empty?

      # Convert array to hash for easier manipulation
      attrs_hash = {}
      # Parse base attributes
      base_attrs.each do |attr|
        if (match = attr.match(/([\w-]+)="([^"]*)"$/))
          attrs_hash[match[1]] = match[2]
        end
      end

      # Parse additional attributes
      additional_attrs.scan(/([\w-]+)="([^"]*)"/) do |key, value|
        if key == "class" && attrs_hash["class"]
          # Merge classes
          attrs_hash["class"] = "#{attrs_hash["class"]} #{value}"
        else
          attrs_hash[key] = value
        end
      end

      # Also parse boolean attributes (attribute name only)
      # Skip any words that are inside ERB tags <%= ... %>
      temp_attrs = additional_attrs.gsub(/<%=.*?%>/, "")
      temp_attrs.scan(/(?:^|\s)([\w-]+)(?=\s|$)/) do |attr|
        attr = attr[0] if attr.is_a?(Array)
        # Skip if this attribute already has a value
        next if attrs_hash.key?(attr)

        attrs_hash[attr] = true
      end

      # Convert back to array
      attrs_hash.map do |k, v|
        if v == true
          k.to_s
        else
          "#{k}=\"#{v}\""
        end
      end
    end

    def build_void_element(tag_name, attributes)
      "#{@indent}<#{tag_name}#{attributes}>\n"
    end

    def build_element_with_ruby(tag_name, attributes)
      "#{@indent}<#{tag_name}#{attributes}><%= #{@tag_info.content} %></#{tag_name}>\n"
    end

    def build_empty_element(tag_name, attributes)
      if @has_children
        "#{@indent}<#{tag_name}#{attributes}>\n"
      else
        "#{@indent}<#{tag_name}#{attributes}></#{tag_name}>\n"
      end
    end

    def build_element_with_content(tag_name, attributes)
      processed_content = StringUtils.process_interpolation(@tag_info.content)

      if @has_children
        "#{@indent}<#{tag_name}#{attributes}>\n"
      else
        "#{@indent}<#{tag_name}#{attributes}>#{processed_content}</#{tag_name}>\n"
      end
    end
  end
end
