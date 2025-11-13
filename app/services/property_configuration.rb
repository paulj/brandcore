# frozen_string_literal: true

require "yaml"
require "liquid"

# PropertyConfiguration manages the configuration for brand properties.
# Each property is defined in a markdown file with YAML frontmatter in config/brand_properties/
#
# Example usage:
#   config = PropertyConfiguration.for("mission")
#   config.property_name  # => "mission"
#   config.cardinality    # => :single
#   config.label          # => "Mission Statement"
#   config.prompt(brand_concept: "...", mission: "...")  # => rendered prompt string
class PropertyConfiguration
  attr_reader :property_name, :cardinality, :input_type, :dependencies, :metadata, :validation, :prompt_template

  # Cache for loaded configurations
  @configurations = {}
  @all_configurations = nil

  class << self
    # Get configuration for a specific property
    # @param property_name [String, Symbol] The property name
    # @return [PropertyConfiguration] The configuration instance
    def for(property_name)
      property_name = property_name.to_s
      @configurations[property_name] ||= load_configuration(property_name)
    end

    # Get all property configurations
    # @return [Array<PropertyConfiguration>] All configurations
    def all
      @all_configurations ||= load_all_configurations
    end

    # Get configurations for a specific section
    # @param section_name [String, Symbol] The section name (e.g., :vision)
    # @return [Array<PropertyConfiguration>] Configurations in that section
    def in_section(section_name)
      all.select { |config| config.section == section_name.to_s }
    end

    # Reload all configurations (useful in development)
    def reload!
      @configurations = {}
      @all_configurations = nil
    end

    private

    def load_configuration(property_name)
      file_path = Rails.root.join("config", "brand_properties", "#{property_name}.md")

      unless File.exist?(file_path)
        raise ArgumentError, "Property configuration file not found: #{file_path}"
      end

      content = File.read(file_path)
      parse_markdown_file(content, property_name)
    end

    def load_all_configurations
      dir_path = Rails.root.join("config", "brand_properties")
      return [] unless Dir.exist?(dir_path)

      Dir.glob(dir_path.join("*.md")).map do |file_path|
        property_name = File.basename(file_path, ".md")
        content = File.read(file_path)
        parse_markdown_file(content, property_name)
      end.sort_by(&:property_name)
    end

    def parse_markdown_file(content, property_name)
      # Split frontmatter and template
      parts = content.split(/^---\s*$/, 3)
      raise ArgumentError, "Invalid markdown file format for #{property_name}" if parts.length < 3

      frontmatter_yaml = parts[1]
      prompt_template = parts[2].strip

      # Parse YAML frontmatter
      frontmatter = YAML.safe_load(frontmatter_yaml, permitted_classes: [ Symbol ])

      new(
        property_name: property_name,
        cardinality: frontmatter["cardinality"]&.to_sym || :single,
        input_type: frontmatter["input_type"]&.to_sym || :text,
        dependencies: frontmatter["dependencies"] || [],
        metadata: frontmatter["metadata"] || {},
        validation: frontmatter["validation"] || {},
        prompt_template: prompt_template
      )
    end
  end

  def initialize(property_name:, cardinality:, input_type:, dependencies:, metadata:, validation:, prompt_template:)
    @property_name = property_name
    @cardinality = cardinality
    @input_type = input_type
    @dependencies = dependencies
    @metadata = metadata
    @validation = validation
    @prompt_template = prompt_template
  end

  # Get the display label from i18n
  def label
    I18n.t("brand_properties.#{property_name}.label", default: property_name.titleize)
  end

  # Get the description from i18n
  def description
    I18n.t("brand_properties.#{property_name}.description", default: "")
  end

  # Get the help text from i18n
  def help_text
    I18n.t("brand_properties.#{property_name}.help_text", default: "")
  end

  # Get the section this property belongs to
  def section
    metadata["section"] || "vision"
  end

  # Get the icon for this property
  def icon
    metadata["icon"] || "fa-solid fa-circle"
  end

  # Get the temperature for AI generation
  def temperature
    metadata["temperature"] || 0.7
  end

  # Get the JSON response key
  def json_key
    metadata["json_key"] || property_name
  end

  # Get the expected count of suggestions
  def count
    metadata["count"] || 3
  end

  # Check if this property is single-cardinality
  def single?
    cardinality == :single
  end

  # Check if this property is multiple-cardinality
  def multiple?
    cardinality == :multiple
  end

  # Check if all dependencies are met for a brand
  # @param brand [Brand] The brand to check
  # @return [Boolean] True if all dependencies have current values
  def dependencies_met?(brand)
    return true if dependencies.empty?

    dependencies.all? do |dep|
      brand.properties.for_property(dep).current.exists?
    end
  end

  # Render the prompt template with the given context
  # @param context [Hash] Variable bindings for the template
  # @return [String] The rendered prompt
  def prompt(context = {})
    template = Liquid::Template.parse(@prompt_template)
    template.render(stringify_keys(context))
  rescue Liquid::SyntaxError => e
    Rails.logger.error("PropertyConfiguration: Liquid template error for #{property_name}: #{e.message}")
    @prompt_template
  end

  # Get a hash representation of this configuration
  def to_h
    {
      property_name: property_name,
      cardinality: cardinality,
      input_type: input_type,
      dependencies: dependencies,
      metadata: metadata,
      validation: validation,
      label: label,
      description: description,
      section: section,
      icon: icon
    }
  end

  private

  def stringify_keys(hash)
    hash.transform_keys(&:to_s).transform_values do |value|
      case value
      when Array
        value
      when Hash
        stringify_keys(value)
      else
        value
      end
    end
  end
end
