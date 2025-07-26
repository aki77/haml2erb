# frozen_string_literal: true

module Haml2erb
  # Merges HTML attributes intelligently
  class AttributeMerger
    def self.merge(base_attributes, additional_attributes)
      new(base_attributes, additional_attributes).merge
    end

    def initialize(base_attributes, additional_attributes)
      @base_attributes = base_attributes || ""
      @additional_attributes = additional_attributes || ""
    end

    def merge
      base_hash = parse_attributes_to_hash(@base_attributes)
      additional_hash = parse_attributes_to_hash(@additional_attributes)

      merged_hash = merge_hashes(base_hash, additional_hash)
      build_attributes_string(merged_hash)
    end

    private

    def parse_attributes_to_hash(attributes_string) # rubocop:todo Metrics/MethodLength
      hash = {}
      return hash if attributes_string.empty?

      # Parse attributes like: class="foo" id="bar" data-test="value"
      attributes_string.scan(/(\S+?)="([^"]*)"/) do |key, value|
        hash[key] = value
      end

      # Parse boolean attributes (without values)
      attributes_string.scan(/(?:^|\s)([\w-]+)(?:\s|$)/) do |key|
        key = key[0] if key.is_a?(Array)
        # Skip if this was already parsed as key="value"
        next if hash.key?(key)

        hash[key] = true
      end

      hash
    end

    def merge_hashes(base, additional) # rubocop:todo Metrics/MethodLength
      merged = base.dup

      additional.each do |key, value|
        if key == "class" && merged["class"]
          # Merge class values
          merged["class"] = merge_class_values(merged["class"], value)
        elsif key == "style" && merged["style"]
          # Merge style values
          merged["style"] = merge_style_values(merged["style"], value)
        else
          # Override other attributes
          merged[key] = value
        end
      end

      merged
    end

    def merge_class_values(base_classes, additional_classes)
      base_list = base_classes.to_s.split
      additional_list = additional_classes.to_s.split
      (base_list + additional_list).uniq.join(" ")
    end

    def merge_style_values(base_styles, additional_styles)
      # Ensure styles end with semicolon
      base = base_styles.to_s.strip
      additional = additional_styles.to_s.strip

      base += ";" unless base.empty? || base.end_with?(";")
      additional += ";" unless additional.empty? || additional.end_with?(";")

      "#{base} #{additional}".strip
    end

    def build_attributes_string(hash)
      return "" if hash.empty?

      attrs = hash.map do |key, value|
        if value == true
          # Boolean attribute
          key
        else
          "#{key}=\"#{value}\""
        end
      end

      " #{attrs.join(" ")}"
    end
  end
end
