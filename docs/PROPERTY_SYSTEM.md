# Brand Property System

## Overview

The Brand Property System is a flexible, configuration-driven approach to managing brand attributes. It replaces the previous hardcoded `brand_visions` table with a dynamic property system that supports:

- **Dynamic properties** defined in markdown configuration files
- **Status lifecycle** for property values (current, suggestion, previous, rejected)
- **AI-powered suggestions** with unified generation service
- **Flexible cardinality** (single or multiple values per property)
- **Dependency management** between properties
- **i18n support** for labels and descriptions

## Architecture

### Data Model

**`BrandProperty` Model:**
```ruby
brand_id         # Reference to brand
property_name    # String identifier (e.g., 'mission', 'vision', 'keyword')
value            # JSONB - flexible storage for any value type
status           # Enum: current, suggestion, previous, rejected_suggestion
generated_at     # When AI generated this suggestion
accepted_at      # When suggestion became current
metadata         # JSONB for additional data
```

### Property Configuration

Properties are defined in markdown files: `/config/brand_properties/*.md`

**Example: `mission.md`**
```markdown
---
property_name: mission
cardinality: single
input_type: textarea
dependencies: []
metadata:
  icon: fa-solid fa-bullseye
  section: vision
  temperature: 0.8
  json_key: mission_statements
  count: 3
validation:
  max_length: 500
---

[Liquid template with AI prompt here]
```

**Configuration Fields:**
- `property_name` - Unique identifier
- `cardinality` - `:single` or `:multiple`
- `input_type` - `:text`, `:textarea`, `:tags`, `:structured`
- `dependencies` - Array of property names that must be set first
- `metadata` - Icon, section, AI parameters, etc.
- `validation` - Validation rules
- Template body - Liquid template for AI prompt generation

### i18n Strings

Labels and descriptions are stored in `/config/locales/en.yml`:

```yaml
brand_properties:
  mission:
    label: "Mission Statement"
    description: "What your brand does and why it exists"
    help_text: "A concise statement of your brand's purpose"
```

## Components

### Services

**`PropertyConfiguration`** - Loads and manages property configurations from markdown files
- `PropertyConfiguration.for(property_name)` - Get configuration
- `PropertyConfiguration.all` - All configurations
- `PropertyConfiguration.in_section(section)` - Filter by section

**`PropertyGeneratorService`** - Unified AI generation service
- Uses PropertyConfiguration to get prompts
- Builds context from brand and existing properties
- Creates BrandProperty objects with status: suggestion

### Jobs

**`GeneratePropertySuggestionsJob`** - Background job for AI generation
- Takes brand_id and property_name
- Generates suggestions asynchronously
- Broadcasts results via Turbo Streams

### Controllers

**`Brand::PropertiesController`** - Unified property management
- `create` - Create/update current property value
- `update` - Update existing property
- `accept` - Accept a suggestion (handles single/multiple cardinality)
- `reject` - Reject a suggestion
- `generate` - Trigger AI generation

### Views

**Property Card Partial:** `brand/properties/_property_card.html.erb`
```erb
<%= render "brand/properties/property_card",
  brand: @brand,
  property_name: "mission" %>
```

**Field Partials:**
- `fields/_text.html.erb` - Single-line text input
- `fields/_textarea.html.erb` - Multi-line text input
- `fields/_tags.html.erb` - Tag/pill input for multiple values

**Suggestion Partials:**
- `_suggestions.html.erb` - Display suggestions (adapts to input type)
- `_suggestion_loading.html.erb` - Loading state
- `_suggestion_error.html.erb` - Error state

## Property Lifecycle

### Single-Cardinality Properties (e.g., mission, vision)

1. User requests AI suggestions → Status: `suggestion`
2. User accepts one → That becomes `current`, others become `rejected_suggestion`, old current becomes `previous`
3. User manually edits → Updates `current` value

### Multiple-Cardinality Properties (e.g., keywords, markets)

1. User requests AI suggestions → Multiple status: `suggestion`
2. User accepts one → That becomes `current`, others remain `suggestion`
3. User can accept multiple suggestions → All become `current`
4. User manually adds → Creates new `current` property

## Status Transitions

```
               generate
[none] ────────────────────→ [suggestion]
                                   │
                            accept │ reject
                                   │
         ┌─────────────────────────┴──────────────────┐
         ↓                                            ↓
    [current] ←─── accept new ─── [suggestion]  [rejected_suggestion]
         │
         │ (when accepting new suggestion)
         ↓
    [previous]
```

## Adding New Properties

1. **Create configuration file:** `/config/brand_properties/new_property.md`
   - Define frontmatter with metadata
   - Write Liquid template for AI prompt

2. **Add i18n strings:** `/config/locales/en.yml`
   ```yaml
   brand_properties:
     new_property:
       label: "Display Name"
       description: "Brief description"
       help_text: "Helpful placeholder text"
   ```

3. **Add to view:** Update `/app/views/brand/vision/show.html.erb`
   ```erb
   <%= render "brand/properties/property_card",
     brand: @brand,
     property_name: "new_property" %>
   ```

That's it! The system handles the rest automatically.

## Benefits

1. **No code changes needed** to add new properties
2. **Unified codebase** - one controller, service, job for all properties
3. **Built-in versioning** - previous values are preserved
4. **Suggestion management** - accept/reject workflow built-in
5. **Dependency tracking** - properties can require others to be set first
6. **i18n ready** - easy to add multiple languages later
7. **Flexible prompts** - easily tweak AI generation without code changes

## Migration from BrandVision

The old `brand_visions` table has been dropped. To migrate existing data:

1. The migration creates the `brand_properties` table
2. Old generator services moved to `app/services/deprecated/`
3. Old jobs moved to `app/jobs/deprecated/`
4. Old vision controller actions removed
5. Old field partials preserved in `app/views/brand/vision/*.old`

## Examples

### Query Property Values

```ruby
# Get current mission statement
mission = brand.properties.for_property('mission').current.first
mission.value # => "Our mission statement"

# Get all current keywords
keywords = brand.properties.for_property('keyword').current
keywords.map(&:value) # => ["innovation", "quality", "customer-first"]

# Get suggestions
suggestions = brand.properties.for_property('mission').suggestions

# Get history
previous = brand.properties.for_property('mission').previous.order(accepted_at: :desc)
```

### Accept Suggestion

```ruby
# In controller (already handled by PropertiesController)
property = brand.properties.find(suggestion_id)
property.accept!(cardinality: :single) # or :multiple
```

### Generate Suggestions

```ruby
# Trigger generation (already handled by PropertiesController)
GeneratePropertySuggestionsJob.perform_later(brand.id, 'mission')
```

## Future Enhancements

- Structured property types (e.g., core values with name/description/icon)
- Property validation rules in configuration
- Export/import property configurations
- Property templates/presets
- Multi-language prompt templates
- Property analytics and insights
