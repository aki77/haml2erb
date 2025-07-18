# frozen_string_literal: true

require_relative "haml2erb/version"
require_relative "haml2erb/converter"

module Haml2erb # rubocop:todo Style/Documentation
  class Error < StandardError; end

  def self.convert(haml_content)
    Converter.new(haml_content).convert
  end
end
