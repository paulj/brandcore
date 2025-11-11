# JSONB vs Normalized Tables: Architectural Decision

## The Question

Should we store complex structured data (colour palettes, token assignments, typography scales) as JSONB blobs, or normalize them into proper relational tables?

## Current Proposal (JSONB-Heavy)

```ruby
# brand_colours table
- palette (jsonb) - All palette colors with shades
- token_assignments (jsonb) - All semantic token mappings
- accessibility_analysis (jsonb) - Cached analysis results
```

**Pros:**
- ✅ Flexible schema evolution
- ✅ Simpler for deeply nested data
- ✅ Fewer tables to manage
- ✅ Easy to store variable-structure data
- ✅ Good Postgres support with GIN indexes

**Cons:**
- ❌ No referential integrity
- ❌ No database-level validation
- ❌ Harder to query specific fields
- ❌ Can become a "junk drawer" over time
- ❌ Migration scripts needed for data shape changes
- ❌ Less discoverable schema
- ❌ Complex testing (need to know JSON structure)
- ❌ Difficult to add foreign keys or constraints
- ❌ Poor support for analytics/reporting queries

## Alternative: Normalized Tables

### Proposed Normalized Schema

#### Palette Colors

```ruby
# palette_colours
- id (primary key)
- brand_colours_id (foreign key)
- colour_identifier (string) - e.g., "ocean-blue"
- name (string) - e.g., "Ocean Blue"
- base_hex (string)
- base_rgb (string)
- base_hsl (string)
- base_cmyk (string, nullable)
- category (enum: primary, secondary, accent, neutral, semantic)
- position (integer) - Sort order
- created_at
- updated_at

# palette_shades
- id (primary key)
- palette_colour_id (foreign key)
- stop (integer) - e.g., 50, 100, 200...900
- hex (string)
- rgb (string, nullable)
- hsl (string, nullable)
- name (string) - e.g., "Ocean Blue 500"
- created_at
- updated_at
```

#### Token Assignments

```ruby
# token_assignments
- id (primary key)
- brand_colours_id (foreign key)
- token_role (string) - e.g., "surface-base", "content-primary"
  - Indexed for fast lookups
- palette_colour_id (foreign key to palette_colours)
- shade_stop (integer, nullable) - Which shade from spectrum
- override_hex (string, nullable) - Optional override instead of palette reference
- created_at
- updated_at

# Unique constraint on [brand_colours_id, token_role]
```

#### Accessibility Analysis (Keep as JSONB)

This is **cached computed data** that:
- Changes frequently as tokens are adjusted
- Has variable structure as new checks are added
- Doesn't need to be queried by individual fields
- Is regenerated, not edited directly

```ruby
# brand_colours
- accessibility_analysis (jsonb) - Keep as JSONB
- accessibility_last_analyzed_at (datetime)
```

**Pros:**
- ✅ Database enforces data integrity
- ✅ Foreign keys prevent orphaned references
- ✅ Easy to query: `PaletteColour.where(category: 'primary')`
- ✅ Easy to add indexes on specific fields
- ✅ Clear schema visible in `schema.rb`
- ✅ Simpler to test (ActiveRecord validations)
- ✅ Better for reporting/analytics
- ✅ Can use joins efficiently
- ✅ Supports database constraints (unique, not null)

**Cons:**
- ❌ More tables (2 additional tables)
- ❌ Migrations required for schema changes
- ❌ More complex joins for some queries
- ❌ Potentially over-engineered for simple cases

## Detailed Comparison

### Example: Finding All Token Assignments Using Primary Colors

**JSONB Approach:**
```ruby
# Must parse JSONB in Ruby
brand.brand_colours.token_assignments['assignments'].select do |assignment|
  colour = brand.brand_colours.palette['colors'].find { |c| c['id'] == assignment['palette_colour_id'] }
  color['category'] == 'primary'
end
```

**Normalized Approach:**
```ruby
# Clean ActiveRecord query
brand.brand_colours.token_assignments
  .joins(:palette_color)
  .where(palette_colours: { category: 'primary' })
```

### Example: Changing Color Category from "Secondary" to "Primary"

**JSONB Approach:**
```ruby
# Must load, modify, and save entire JSON blob
palette = brand.brand_colours.palette
colour = palette['colors'].find { |c| c['id'] == 'ocean-blue' }
color['category'] = 'primary'
brand.brand_colours.update!(palette: palette)

# Risk: Race conditions if multiple users edit simultaneously
# Risk: Validation happens in Ruby, not database
```

**Normalized Approach:**
```ruby
# Simple update, database handles concurrency
PaletteColour.find_by(colour_identifier: 'ocean-blue').update!(category: 'primary')

# Database guarantees integrity
# Triggers/callbacks work naturally
# PaperTrail tracks the specific change
```

### Example: Adding a New Required Field

**JSONB Approach:**
```ruby
# Need migration to update existing records
class AddDescriptionToPaletteColours < ActiveRecord::Migration[7.0]
  def up
    BrandColors.find_each do |brand_colours|
      palette = brand_colours.palette
      palette['colors'].each do |color|
        color['description'] ||= '' # Add default value
      end
      brand_colours.update!(palette: palette)
    end
  end
end

# Future code needs to handle both old and new structures
# Or run expensive migration to transform all existing data
```

**Normalized Approach:**
```ruby
# Standard Rails migration
class AddDescriptionToPaletteColours < ActiveRecord::Migration[7.0]
  def change
    add_column :palette_colours, :description, :text
  end
end

# All existing records automatically have NULL
# Can add default, not null constraint if needed
```

## Hybrid Approach (Recommended)

Use the **right tool for each data type**:

### Use Normalized Tables For:

1. **Palette Colors & Shades**
   - Core data model
   - Queried frequently
   - Referenced by foreign keys
   - Benefits from constraints

2. **Token Assignments**
   - Need to query by token role
   - Join with palette colors
   - Unique constraints needed

3. **Core Values** (in BrandVision)
   - Separate `core_values` table
   - Can tag, search, reference individually

4. **Typography Type Scale**
   - Separate `type_scale_definitions` table
   - Can validate, query each level

### Keep JSONB For:

1. **Accessibility Analysis**
   - Cached computed results
   - Variable structure (new checks added)
   - Regenerated, not edited

2. **Aesthetic Analysis**
   - Similar to accessibility analysis
   - Computed scores and suggestions

3. **Usage Guidelines** (text explanations)
   - Free-form content
   - Not queried by individual fields
   - Simple key-value pairs

4. **Component Patterns** (in BrandUI)
   - Complex nested structures
   - Varies significantly between brands
   - More like configuration than data

### Updated Schema

```ruby
# brand_colours
- id
- brand_id (foreign key)
- palette_generation_method (string)
- usage_guidelines (text)
- completed (boolean)
- completed_at (datetime)
- accessibility_analysis (jsonb) - KEPT as JSONB (cached)
- aesthetic_analysis (jsonb) - KEPT as JSONB (cached)
- timestamps

# palette_colours - NEW TABLE
- id
- brand_colours_id (foreign key)
- colour_identifier (string, indexed)
- name (string)
- base_hex (string)
- base_rgb (string)
- base_hsl (string)
- category (enum)
- position (integer)
- timestamps

# palette_shades - NEW TABLE
- id
- palette_colour_id (foreign key)
- stop (integer)
- hex (string)
- rgb (string)
- name (string)
- timestamps

# token_assignments - NEW TABLE
- id
- brand_colours_id (foreign key)
- token_role (string, indexed)
- palette_colour_id (foreign key, nullable)
- shade_stop (integer, nullable)
- override_hex (string, nullable)
- timestamps
# Unique index on [brand_colours_id, token_role]

# core_values - NEW TABLE (extracted from BrandVision)
- id
- brand_vision_id (foreign key)
- value (string) - e.g., "Integrity"
- description (text)
- position (integer)
- timestamps

# type_scale_definitions - NEW TABLE (extracted from BrandTypography)
- id
- brand_typography_id (foreign key)
- level (string) - e.g., "h1", "h2", "body"
- size (string) - e.g., "48px"
- line_height (decimal)
- position (integer)
- timestamps
```

## Migration Path

If we start with JSONB and want to normalize later:

1. **Create normalized tables** (run migrations)
2. **Write migration to extract JSONB → tables**
3. **Keep JSONB column temporarily** (for rollback safety)
4. **Update code to use new tables**
5. **Deploy and verify**
6. **Remove JSONB column in future migration**

Example migration:

```ruby
class NormalizePaletteColours < ActiveRecord::Migration[7.0]
  def up
    # Create new tables
    create_table :palette_colours do |t|
      t.references :brand_colours, null: false, foreign_key: true
      t.string :colour_identifier, null: false
      t.string :name, null: false
      t.string :base_hex, null: false
      # ... other columns
      t.timestamps
    end

    # Extract JSONB data
    BrandColors.find_each do |brand_colours|
      next unless brand_colours.palette

      brand_colours.palette['colors'].each do |color_data|
        palette_colour = PaletteColour.create!(
          brand_colours: brand_colours,
          colour_identifier: color_data['id'],
          name: color_data['name'],
          base_hex: color_data['base']['hex'],
          # ... other fields
        )

        # Extract shades
        color_data['shades']&.each do |shade_data|
          PaletteShade.create!(
            palette_color: palette_color,
            stop: shade_data['stop'],
            hex: shade_data['hex'],
            name: shade_data['name']
          )
        end
      end
    end

    # Optionally: rename palette to palette_deprecated
    # Don't drop yet - keep for rollback safety
    rename_column :brand_colours, :palette, :palette_deprecated
  end

  def down
    # Can restore from palette_deprecated if needed
    drop_table :palette_shades
    drop_table :palette_colours
    rename_column :brand_colours, :palette_deprecated, :palette
  end
end
```

## Recommendation

**Start with a hybrid approach:**

1. **Normalize the core data:**
   - Palette colors & shades (will be queried, joined)
   - Token assignments (need constraints)
   - Core values (might want to search/tag)
   - Type scale (fixed set of levels)

2. **Keep JSONB for:**
   - Analysis results (cached computed data)
   - Free-form guidelines (text)
   - Truly variable structures

3. **Benefits:**
   - Database enforces critical data integrity
   - Easy to query and report on core data
   - Still flexible where needed
   - Better long-term maintainability
   - Clearer for new developers

4. **Trade-offs accepted:**
   - 4-6 more tables in the schema
   - Migrations required for schema changes (but that's good - explicit!)
   - Slightly more complex joins (but more performant)

## Updated Model Relationships

```ruby
class BrandColors < ApplicationRecord
  belongs_to :brand
  has_many :palette_colours, dependent: :destroy
  has_many :token_assignments, dependent: :destroy
  has_many :palette_shades, through: :palette_colours

  # Delegations for convenience
  def find_token(role)
    token_assignments.find_by(token_role: role)
  end

  def primary_colors
    palette_colours.where(category: 'primary').order(:position)
  end
end

class PaletteColour < ApplicationRecord
  belongs_to :brand_colours
  has_many :palette_shades, -> { order(:stop) }, dependent: :destroy
  has_many :token_assignments, dependent: :restrict_with_error

  validates :colour_identifier, presence: true, uniqueness: { scope: :brand_colours_id }
  validates :base_hex, presence: true, format: { with: /\A#[0-9A-F]{6}\z/i }
  validates :category, inclusion: { in: %w[primary secondary accent neutral semantic] }

  def shade_at(stop)
    palette_shades.find_by(stop: stop)
  end
end

class TokenAssignment < ApplicationRecord
  belongs_to :brand_colours
  belongs_to :palette_colour, optional: true

  validates :token_role, presence: true, uniqueness: { scope: :brand_colours_id }
  validate :has_colour_source

  private

  def has_colour_source
    if palette_colour.nil? && override_hex.nil?
      errors.add(:base, "Must have either palette_colour or override_hex")
    end
  end
end
```

## Testing Comparison

**JSONB:**
```ruby
it 'assigns ocean blue to surface-base token' do
  assignments = brand.brand_colours.token_assignments['assignments']
  surface_base = assignments.find { |a| a['token_role'] == 'surface-base' }
  expect(surface_base['palette_colour_id']).to eq('ocean-blue')
end
```

**Normalized:**
```ruby
it 'assigns ocean blue to surface-base token' do
  ocean_blue = brand.brand_colours.palette_colours.find_by(colour_identifier: 'ocean-blue')
  surface_base = brand.brand_colours.token_assignments.find_by(token_role: 'surface-base')
  expect(surface_base.palette_colour).to eq(ocean_blue)
end
```

The normalized version has better IDE support, type safety, and is easier to understand.

## Decision

**Use the hybrid approach** with normalized tables for core data model and JSONB for cached/computed results. This provides:

- ✅ Database integrity for critical data
- ✅ Flexibility where truly needed
- ✅ Better long-term maintainability
- ✅ Easier to understand and test
- ✅ Better query performance
- ✅ Clear evolution path

The upfront cost of a few more tables is worth the long-term benefits of data integrity and queryability.
