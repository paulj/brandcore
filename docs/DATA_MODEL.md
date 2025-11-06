# BrandCore Data Model

## Overview

The data model is designed to support:
- Brands as independent entities with multiple users
- Complete version history via PaperTrail gem
- Structured storage of all seven brand components
- Asset management (logos, fonts, images)
- Draft and published states
- Sharing and collaboration

## Core Entities

### Users
Standard authentication using Rails built-in generators (not Devise).

```ruby
# users
- id (primary key)
- email (string, unique, indexed)
- password_digest (string) - Rails has_secure_password
- name (string)
- timestamps
```

**Key relationships:**
- `has_many :brand_memberships`
- `has_many :brands, through: :brand_memberships`

### Brands
The root entity for each brand. **Brands exist independently** and have multiple users associated with them.

```ruby
# brands
- id (primary key)
- name (string) - The brand name (can be working/generated name)
- slug (string, unique, indexed) - For URL access (e.g., /brands/acme-corp)
- is_working_name (boolean, default: true) - True if using generated name
- status (enum: draft, published, archived)
- created_at
- updated_at
```

**Working Name Generation:**
When creating a brand, if user doesn't provide a name, auto-generate using format:
`[Adjective] [Noun]` - e.g., "Bold Canvas", "Swift Harbor", "Clear Compass"

Store a curated list of brand-relevant adjectives and nouns:
```ruby
# Embedded in app (config/initializers/brand_names.rb)
BRAND_ADJECTIVES = %w[
  Bold Bright Clear Swift Noble Wise True Pure
  Vital Prime Core Keen Lucid Vivid Solid Fresh
]

BRAND_NOUNS = %w[
  Canvas Harbor Compass Atlas Summit Beacon Peak
  Forge Studio Craft Union Guild Foundation Stone
]
```

User can keep working name while developing vision, then finalize later.

**Key relationships:**
- `has_many :brand_memberships, dependent: :destroy`
- `has_many :users, through: :brand_memberships`
- `has_paper_trail` - Version history via PaperTrail gem

### Brand Memberships
Join table linking users to brands with role-based access.

```ruby
# brand_memberships
- id (primary key)
- brand_id (foreign key, indexed)
- user_id (foreign key, indexed)
- role (enum: owner, editor, viewer)
- invited_by_user_id (foreign key to users, nullable)
- created_at
- updated_at
```

**Key relationships:**
- `belongs_to :brand`
- `belongs_to :user`
- `belongs_to :invited_by, class_name: 'User', optional: true`

**Unique constraint:** `[brand_id, user_id]`

### Version History (PaperTrail)

**Using `paper_trail` gem instead of custom versioning.**

All brand component models will use PaperTrail:

```ruby
class Brand < ApplicationRecord
  has_paper_trail
end

class BrandVision < ApplicationRecord
  has_paper_trail
end

# ... all component models
```

This provides:
- Automatic version snapshots on changes
- `brand.versions` - Access all historical versions
- `brand.paper_trail.previous_version` - Get previous state
- `brand.paper_trail.version_at(timestamp)` - Time travel
- Tracks `whodunnit` (which user made change)
- Revert capability: `brand.paper_trail.previous_version.reify.save!`

### Completion Tracking

Add completion flags directly on component tables (see below). Each component table has:
```ruby
- completed (boolean, default: false)
- completed_at (datetime, nullable)
```

Brand model has computed properties:
```ruby
def completion_percentage
  # Count completed components / 7 * 100
end

def completed_components
  # Array of component names that exist and are marked completed
end
```

### Brand Component Tables

Each of the seven brand components has its own table, linked to a specific brand version.

#### Brand Names

```ruby
# brand_names
- id (primary key)
- brand_id (foreign key, indexed, unique)
- name (string) - The official brand name
- domain_primary (string) - Primary domain (e.g., "acme.com")
- domain_alternatives (jsonb) - Array of alternative domains checked/acquired
- name_rationale (text) - Why this name was chosen
- name_alternatives_considered (jsonb) - Array of names that were considered
- completed (boolean, default: false)
- completed_at (datetime, nullable)
- created_at
- updated_at
```

**Key relationships:**
- `belongs_to :brand`
- `has_paper_trail`

#### Brand Visions

```ruby
# brand_visions
- id (primary key)
- brand_id (foreign key, indexed, unique)
- mission_statement (text)
- vision_statement (text)
- core_values (jsonb) - Array of values with descriptions
  # [{ value: "Integrity", description: "We act with honesty..." }, ...]
- brand_positioning (text)
- target_audience (text)
- brand_personality (jsonb) - Structured personality attributes
  # { traits: ["Innovative", "Approachable"], voice: "Friendly yet professional" }
- completed (boolean, default: false)
- completed_at (datetime, nullable)
- created_at
- updated_at
```

**Key relationships:**
- `belongs_to :brand`
- `has_paper_trail`

#### Brand Logos

```ruby
# brand_logos
- id (primary key)
- brand_id (foreign key, indexed, unique)
- logo_philosophy (text) - Design thinking behind the logo
- usage_guidelines (jsonb)
  # {
  #   minimum_size: "40px",
  #   clear_space: "Equal to height of logo",
  #   acceptable_uses: ["On white background", "On brand primary color"],
  #   unacceptable_uses: ["Stretching or distorting", "Rotating"]
  # }
- completed (boolean, default: false)
- completed_at (datetime, nullable)
- created_at
- updated_at
```

**ActiveStorage attachments:**
- `has_one_attached :primary_logo`
- `has_many_attached :logo_variations` - Secondary versions, monochrome, etc.

**Key relationships:**
- `belongs_to :brand`
- `has_paper_trail` (Note: PaperTrail tracks attachment changes separately)

#### Brand Language

```ruby
# brand_languages
- id (primary key)
- brand_id (foreign key, indexed, unique)
- tone_of_voice (jsonb)
  # { descriptor: "Professional yet approachable", characteristics: [...] }
- messaging_pillars (jsonb) - Array of key messages
  # [{ pillar: "Innovation", message: "We're always looking forward" }, ...]
- tagline (string)
- vocabulary_guidelines (jsonb)
  # { use: ["customer", "partner"], avoid: ["user", "client"] }
- writing_style_notes (text)
- example_copy (text) - Sample text demonstrating the brand voice
- completed (boolean, default: false)
- completed_at (datetime, nullable)
- created_at
- updated_at
```

**Key relationships:**
- `belongs_to :brand`
- `has_paper_trail`

#### Brand Colors

**See `docs/DESIGN_TOKENS.md` for comprehensive token philosophy.**
**See `docs/JSONB_VS_NORMALIZED.md` for architecture decision rationale.**

Using a **hybrid approach**: normalized tables for core data, JSONB for cached results.

```ruby
# brand_colors (parent table)
- id (primary key)
- brand_id (foreign key, indexed, unique)
- palette_generation_method (string) - "manual", "auto", "imported"
- usage_guidelines (text)
- completed (boolean, default: false)
- completed_at (datetime, nullable)

# ANALYSIS RESULTS (cached, kept as JSONB)
- accessibility_analysis (jsonb)
  # { wcag_level: "AA", issues: [...], contrast_matrix: {...} }
- aesthetic_analysis (jsonb)
  # { harmony_score: 85, suggestions: [...] }
- accessibility_last_analyzed_at (datetime)

- created_at
- updated_at

# palette_colors (NORMALIZED - was JSONB)
- id (primary key)
- brand_colors_id (foreign key, indexed)
- color_identifier (string) - e.g., "ocean-blue" (unique per brand_colors)
- name (string) - e.g., "Ocean Blue"
- base_hex (string) - e.g., "#0066CC"
- base_rgb (string) - e.g., "0, 102, 204"
- base_hsl (string) - e.g., "210, 100%, 40%"
- base_cmyk (string, nullable)
- category (enum: primary, secondary, accent, neutral, semantic)
- position (integer) - Sort order
- created_at
- updated_at

# palette_shades (NORMALIZED - was nested in JSONB)
- id (primary key)
- palette_color_id (foreign key, indexed)
- stop (integer) - e.g., 50, 100, 200...900
- hex (string)
- rgb (string, nullable)
- hsl (string, nullable)
- name (string) - e.g., "Ocean Blue 500"
- created_at
- updated_at

# token_assignments (NORMALIZED - was JSONB)
- id (primary key)
- brand_colors_id (foreign key, indexed)
- token_role (string, indexed) - e.g., "surface-base", "content-primary"
- palette_color_id (foreign key to palette_colors, nullable)
- shade_stop (integer, nullable) - Which shade to use
- override_hex (string, nullable) - Direct color instead of palette reference
- created_at
- updated_at
# Unique constraint on [brand_colors_id, token_role]
```

**Key relationships:**
- `belongs_to :brand`
- `has_many :palette_colors, dependent: :destroy`
- `has_many :palette_shades, through: :palette_colors`
- `has_many :token_assignments, dependent: :destroy`
- `has_paper_trail`

**Why normalized?**
- Frequent queries by token role, color category
- Need foreign key integrity (token → palette color)
- Unique constraints on token roles
- Better for reporting and analytics
- Clear schema evolution via migrations
- See `docs/JSONB_VS_NORMALIZED.md` for full analysis

#### Brand Typography

```ruby
# brand_typographies
- id (primary key)
- brand_id (foreign key, indexed, unique)
- primary_typeface (jsonb)
  # { name: "Inter", weights: [400, 600, 700], usage: "Headlines and UI" }
- secondary_typeface (jsonb) - Same structure
- type_scale (jsonb)
  # { h1: "48px", h2: "36px", h3: "24px", body: "16px", small: "14px" }
- line_heights (jsonb)
  # { heading: 1.2, body: 1.5 }
- usage_guidelines (text)
- web_font_urls (jsonb) - Google Fonts URLs or similar
- completed (boolean, default: false)
- completed_at (datetime, nullable)
- created_at
- updated_at
```

**ActiveStorage attachments:**
- `has_many_attached :font_files` - For custom/licensed fonts

**Key relationships:**
- `belongs_to :brand`
- `has_paper_trail`

#### Brand UI

```ruby
# brand_uis
- id (primary key)
- brand_id (foreign key, indexed, unique)
- button_styles (jsonb)
  # {
  #   primary: { background: "var(--interactive-primary)", radius: "8px", padding: "12px 24px" },
  #   secondary: { ... }
  # }
- form_elements (jsonb) - Input styles, validation states
- iconography (jsonb)
  # { style: "outline", stroke_width: "2px", library: "Heroicons" }
- spacing_system (jsonb)
  # { base: "8px", scale: [8, 16, 24, 32, 48, 64, 96] }
- grid_system (jsonb)
  # { columns: 12, gutter: "24px", breakpoints: {...} }
- component_patterns (jsonb) - Cards, modals, navigation, etc.
- completed (boolean, default: false)
- completed_at (datetime, nullable)
- created_at
- updated_at
```

**ActiveStorage attachments:**
- `has_many_attached :component_examples` - Screenshots or design files

**Key relationships:**
- `belongs_to :brand`
- `has_paper_trail`

## Supporting Entities

### Domain Checks
Track domain availability checks for brand naming.

```ruby
# domain_checks
- id (primary key)
- brand_id (foreign key, indexed)
- domain_name (string, indexed)
- tld (string) - e.g., "com", "io", "net"
- is_available (boolean)
- checked_at (datetime)
- price (decimal) - If available for purchase
- registrar (string) - Where it's available
- created_at
```

### Brand Shares
Manage public/private access and sharing.

```ruby
# brand_shares
- id (primary key)
- brand_id (foreign key, indexed)
- share_token (string, unique, indexed) - For public URLs
- is_public (boolean, default: false)
- is_password_protected (boolean, default: false)
- password_digest (string) - If password protected
- expires_at (datetime, nullable)
- view_count (integer, default: 0)
- created_at
- updated_at
```


## Indexes

Critical indexes for performance:

```ruby
# users
add_index :users, :email, unique: true

# brands
add_index :brands, :slug, unique: true

# brand_memberships
add_index :brand_memberships, :brand_id
add_index :brand_memberships, :user_id
add_index :brand_memberships, [:brand_id, :user_id], unique: true

# All brand component tables (one-to-one with brand)
add_index :brand_names, :brand_id, unique: true
add_index :brand_visions, :brand_id, unique: true
add_index :brand_logos, :brand_id, unique: true
add_index :brand_languages, :brand_id, unique: true
add_index :brand_colors, :brand_id, unique: true
add_index :brand_typographies, :brand_id, unique: true
add_index :brand_uis, :brand_id, unique: true

# Color system normalized tables
add_index :palette_colors, :brand_colors_id
add_index :palette_colors, [:brand_colors_id, :color_identifier], unique: true
add_index :palette_colors, :category
add_index :palette_shades, :palette_color_id
add_index :token_assignments, :brand_colors_id
add_index :token_assignments, [:brand_colors_id, :token_role], unique: true
add_index :token_assignments, :palette_color_id
add_index :token_assignments, :token_role

# domain_checks
add_index :domain_checks, :brand_id
add_index :domain_checks, :domain_name

# brand_shares
add_index :brand_shares, :brand_id
add_index :brand_shares, :share_token, unique: true

# PaperTrail versions table (automatically created by gem)
# Includes indexes on item_type, item_id, created_at
```

## Version History Strategy (PaperTrail)

### Automatic Versioning

PaperTrail automatically creates versions on every update:

```ruby
# Every save creates a version
brand_vision.update(mission_statement: "New mission")

# Access versions
brand_vision.versions.count # => 2
brand_vision.paper_trail.previous_version # => previous state

# Who made the change (set in ApplicationController)
PaperTrail.request.whodunnit = current_user.id

# Version includes metadata
version = brand_vision.versions.last
version.event # => "update"
version.whodunnit # => user_id
version.created_at # => timestamp
```

### Version Comparison & Restoration

```ruby
# Get brand state at a specific time
brand_at_time = brand.paper_trail.version_at(1.week.ago)

# Restore previous version
previous = brand_vision.paper_trail.previous_version
previous.reify.save! # Restores and creates new version

# Compare two versions
v1 = brand_vision.versions[0].reify
v2 = brand_vision.versions[1].reify
changes = v2.attributes.diff(v1.attributes)
```

### Configuration

```ruby
# config/initializers/paper_trail.rb
PaperTrail.config.enabled = true
PaperTrail.config.has_paper_trail_defaults = {
  on: [:create, :update, :destroy]
}

# Set whodunnit in ApplicationController
class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit
end
```

## Presenter Layer Architecture

**Philosophy:** Data transformation and presentation logic lives in **presenters**, not models. Models should focus on data integrity, validation, and persistence. Presenters handle converting structured data into various output formats.

### Why Presenters?

- **Separation of concerns:** Models stay focused on business logic
- **Testability:** Presentation logic can be tested independently
- **Flexibility:** Easy to add new output formats (CSS, JSON, PDF, design tool exports)
- **Reusability:** Same presenter can be used across views and contexts

### Presenter Structure

```
app/
  models/           # Data models (validation, persistence, relationships)
  presenters/       # Presentation logic (data transformation)
    brand_presenters/
      stylesheet_presenter.rb      # Generates CSS variables
      tailwind_presenter.rb        # Generates Tailwind @theme block
      json_presenter.rb            # Generates JSON export
      accessibility_report_presenter.rb  # Formats accessibility analysis
```

### Example: StylesheetPresenter

```ruby
# app/presenters/brand_presenters/stylesheet_presenter.rb
module BrandPresenters
  class StylesheetPresenter
    def initialize(brand)
      @brand = brand
      @colors = brand.brand_colors
      @typography = brand.brand_typography
    end

    def to_css_variables
      {
        **surface_tokens,
        **content_tokens,
        **border_tokens,
        **interactive_tokens,
        **semantic_tokens,
        **typography_tokens
      }
    end

    def to_css_string
      to_css_variables.map { |key, value| "  #{key}: #{value};" }.join("\n")
    end

    private

    def surface_tokens
      return {} unless @colors

      {
        '--surface-base': find_token_color('surface-base'),
        '--surface-1': find_token_color('surface-1'),
        '--surface-2': find_token_color('surface-2'),
        '--surface-3': find_token_color('surface-3'),
        '--surface-overlay': find_token_color('surface-overlay'),
        '--surface-inverse': find_token_color('surface-inverse')
      }
    end

    def content_tokens
      return {} unless @colors

      {
        '--content-primary': find_token_color('content-primary'),
        '--content-secondary': find_token_color('content-secondary'),
        '--content-tertiary': find_token_color('content-tertiary'),
        # ... all content tokens
      }
    end

    def typography_tokens
      return {} unless @typography

      {
        '--font-heading': @typography.primary_typeface['name'],
        '--font-body': @typography.secondary_typeface&.dig('name') || @typography.primary_typeface['name'],
        '--text-h1': @typography.type_scale['h1'],
        '--text-h2': @typography.type_scale['h2'],
        # ... all typography tokens
      }
    end

    def find_token_color(token_role)
      assignment = @colors.token_assignments.find_by(token_role: token_role)
      return nil unless assignment

      # Check for direct override first
      return assignment.override_hex if assignment.override_hex.present?

      # Otherwise, resolve from palette
      palette_color = assignment.palette_color
      return nil unless palette_color

      if assignment.shade_stop
        # Get specific shade from spectrum
        shade = palette_color.palette_shades.find_by(stop: assignment.shade_stop)
        shade&.hex || palette_color.base_hex
      else
        # Use base color
        palette_color.base_hex
      end
    end
  end
end
```

### Example: TailwindPresenter

```ruby
# app/presenters/brand_presenters/tailwind_presenter.rb
module BrandPresenters
  class TailwindPresenter
    def initialize(brand)
      @brand = brand
      @stylesheet_presenter = StylesheetPresenter.new(brand)
    end

    def to_theme_block
      variables = @stylesheet_presenter.to_css_variables

      # Convert from --surface-base format to --color-surface-base format
      tailwind_variables = variables.transform_keys do |key|
        key.to_s.sub(/^--/, '--color-')
      end

      <<~CSS
        @theme {
        #{tailwind_variables.map { |key, value| "  #{key}: #{value};" }.join("\n")}
        }
      CSS
    end
  end
end
```

### Example: AccessibilityReportPresenter

```ruby
# app/presenters/brand_presenters/accessibility_report_presenter.rb
module BrandPresenters
  class AccessibilityReportPresenter
    def initialize(brand)
      @brand = brand
      @colors = brand.brand_colors
      @analysis = @colors&.accessibility_analysis || {}
    end

    def overall_score
      @analysis['overall_score'] || 0
    end

    def wcag_level
      @analysis['wcag_level'] || 'N/A'
    end

    def text_issues
      @analysis['text_issues'] || []
    end

    def border_issues
      @analysis['border_issues'] || []
    end

    def component_issues
      @analysis['component_issues'] || []
    end

    def has_errors?
      all_issues.any? { |issue| issue['severity'] == 'error' }
    end

    def has_warnings?
      all_issues.any? { |issue| issue['severity'] == 'warning' }
    end

    def all_issues
      text_issues + border_issues + component_issues
    end

    def passed_checks
      @analysis['passed_checks'] || []
    end

    # Format for display in views
    def formatted_issues
      all_issues.map do |issue|
        {
          severity: issue['severity'],
          icon: severity_icon(issue['severity']),
          title: issue_title(issue),
          description: issue['suggestion'],
          context: issue_context(issue)
        }
      end
    end

    private

    def severity_icon(severity)
      case severity
      when 'error' then '✗'
      when 'warning' then '⚠'
      else 'ℹ'
      end
    end

    def issue_title(issue)
      issue['token_pair'] || issue['component'] || issue['issue']
    end

    def issue_context(issue)
      if issue['contrast_ratio']
        "Contrast: #{issue['contrast_ratio']}:1 (requires #{issue['required_ratio']}:1)"
      else
        issue['problem']
      end
    end
  end
end
```

### Example: JsonExportPresenter

```ruby
# app/presenters/brand_presenters/json_export_presenter.rb
module BrandPresenters
  class JsonExportPresenter
    def initialize(brand)
      @brand = brand
    end

    def to_design_tokens_json
      # Format compatible with Design Tokens W3C spec
      {
        name: @brand.name,
        colors: color_tokens,
        typography: typography_tokens,
        spacing: spacing_tokens
      }
    end

    def to_figma_tokens
      # Format compatible with Figma Tokens plugin
      {
        global: {
          colors: figma_color_format,
          typography: figma_typography_format
        }
      }
    end

    private

    def color_tokens
      return {} unless @brand.brand_colors

      @brand.brand_colors.palette['colors'].map do |color|
        {
          name: color['name'],
          value: color['base']['hex'],
          type: 'color',
          shades: color['shades']&.map { |s| { stop: s['stop'], value: s['hex'] } }
        }
      end
    end

    # ... more formatting methods
  end
end
```

### Usage in Controllers

```ruby
# app/controllers/brands_controller.rb
class BrandsController < ApplicationController
  def show
    @brand = Brand.find(params[:id])
    @stylesheet = BrandPresenters::StylesheetPresenter.new(@brand)
    @accessibility = BrandPresenters::AccessibilityReportPresenter.new(@brand)
  end
end
```

### Usage in Views

```erb
<!-- app/views/brands/show.html.erb -->
<style>
  :root {
<%= @stylesheet.to_css_string %>
  }
</style>

<div class="accessibility-report">
  <h2>Accessibility Score: <%= @accessibility.overall_score %>%</h2>
  <p>WCAG Level: <%= @accessibility.wcag_level %></p>

  <% if @accessibility.has_errors? %>
    <div class="errors">
      <% @accessibility.formatted_issues.each do |issue| %>
        <div class="issue issue-<%= issue[:severity] %>">
          <%= issue[:icon] %> <%= issue[:title] %>
          <p><%= issue[:description] %></p>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

### Benefits of This Approach

1. **Models stay clean:**
   ```ruby
   # brand.rb - focused on data
   class Brand < ApplicationRecord
     has_one :brand_colors
     validates :name, presence: true
   end
   ```

2. **Multiple presentation formats:**
   ```ruby
   stylesheet = StylesheetPresenter.new(brand)
   tailwind = TailwindPresenter.new(brand)
   json = JsonExportPresenter.new(brand)

   stylesheet.to_css_string  # For <style> tags
   tailwind.to_theme_block   # For Tailwind config
   json.to_figma_tokens      # For Figma export
   ```

3. **Easy testing:**
   ```ruby
   # spec/presenters/brand_presenters/stylesheet_presenter_spec.rb
   RSpec.describe BrandPresenters::StylesheetPresenter do
     let(:brand) { create(:brand, :with_colors) }
     let(:presenter) { described_class.new(brand) }

     it 'generates CSS variables for all token roles' do
       css = presenter.to_css_variables
       expect(css).to include('--surface-base')
       expect(css).to include('--content-primary')
     end
   end
   ```

4. **Cacheable:**
   ```ruby
   # Cache expensive transformations
   def brand_stylesheet
     Rails.cache.fetch(['brand-stylesheet', @brand.id, @brand.updated_at]) do
       BrandPresenters::StylesheetPresenter.new(@brand).to_css_string
     end
   end
   ```

## Data Integrity

### Constraints

- A Brand can exist without components (they're created as needed)
- Each component table has one-to-one relationship with Brand (unique index)
- BrandMembership requires unique [brand_id, user_id] pair
- At least one user must be "owner" role per brand

### Validations

```ruby
class Brand < ApplicationRecord
  has_paper_trail

  has_many :brand_memberships, dependent: :destroy
  has_many :users, through: :brand_memberships

  has_one :brand_name, dependent: :destroy
  has_one :brand_vision, dependent: :destroy
  has_one :brand_logo, dependent: :destroy
  has_one :brand_language, dependent: :destroy
  has_one :brand_colors, dependent: :destroy
  has_one :brand_typography, dependent: :destroy
  has_one :brand_ui, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :status, inclusion: { in: %w[draft published archived] }

  before_validation :generate_slug, if: :name_changed?
  before_validation :generate_working_name, if: -> { name.blank? }

  def completion_percentage
    components = [brand_name, brand_vision, brand_logo, brand_language,
                  brand_colors, brand_typography, brand_ui]
    completed = components.count { |c| c&.completed? }
    (completed.to_f / 7 * 100).round
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end

  def generate_working_name
    adjective = BRAND_ADJECTIVES.sample
    noun = BRAND_NOUNS.sample
    self.name = "#{adjective} #{noun}"
    self.is_working_name = true
  end
end

class BrandMembership < ApplicationRecord
  belongs_to :brand
  belongs_to :user
  belongs_to :invited_by, class_name: 'User', optional: true

  validates :brand_id, uniqueness: { scope: :user_id }
  validates :role, inclusion: { in: %w[owner editor viewer] }

  validate :at_least_one_owner

  private

  def at_least_one_owner
    if role_changed? && role_was == 'owner'
      remaining_owners = brand.brand_memberships.where(role: 'owner').where.not(id: id).count
      errors.add(:role, "cannot be changed - brand must have at least one owner") if remaining_owners.zero?
    end
  end
end
```

## Migration Strategy

Suggested migration order:

1. **Users** - `rails generate model User`
2. **PaperTrail** - `bundle add paper_trail && rails generate paper_trail:install`
3. **Brands** - `rails generate model Brand`
4. **BrandMemberships** - `rails generate model BrandMembership`
5. **Component tables** (can be parallel):
   - `rails generate model BrandName`
   - `rails generate model BrandVision`
   - `rails generate model BrandLogo`
   - `rails generate model BrandLanguage`
   - `rails generate model BrandColors`
   - `rails generate model BrandTypography`
   - `rails generate model BrandUi`
6. **Color system normalized tables**:
   - `rails generate model PaletteColor`
   - `rails generate model PaletteShade`
   - `rails generate model TokenAssignment`
7. **DomainChecks** - `rails generate model DomainCheck`
8. **BrandShares** - `rails generate model BrandShare`
9. **ActiveStorage** - `rails active_storage:install`

## Architecture Patterns

### Key Decisions

1. **Presenter Layer for Data Transformation**
   - All formatting/transformation logic lives in presenters
   - Models focus on data integrity and business logic
   - Easy to add new export formats (PDF, Sketch, Adobe XD)

2. **Hybrid: Normalized + JSONB**
   - Core data (palettes, token assignments) in normalized tables
   - Cached/computed results (accessibility analysis) in JSONB
   - Best of both worlds: integrity + flexibility
   - See `docs/JSONB_VS_NORMALIZED.md` for full analysis

3. **PaperTrail for Version History**
   - Automatic versioning without custom tables
   - Tracks who made changes
   - Time-travel and comparison capabilities

4. **One-to-One Component Relationships**
   - Each brand has one of each component type
   - Simplifies queries and reduces complexity
   - Version history handled by PaperTrail, not separate records

### Presenter Examples

- `StylesheetPresenter` - CSS variables
- `TailwindPresenter` - Tailwind 4 @theme blocks
- `AccessibilityReportPresenter` - Formatted WCAG reports
- `JsonExportPresenter` - Design tool exports
- Future: `PdfPresenter`, `SketchPresenter`, `FigmaPresenter`

## Future Considerations

### Potential additions:

- **Brand Templates:** Seed common starting points (models + presenters)
- **Asset Library:** Separate table for reusable brand assets
- **Export History:** Track PDF exports, downloads
- **Analytics:** Track which sections are viewed most, time spent
- **Comments/Feedback:** Inline comments on brand book sections
- **AI Suggestions:** Store AI-generated alternatives for components
- **Real-time Collaboration:** Operational transforms for simultaneous editing
- **Additional Presenters:** PDF export, design tool sync (Sketch, Adobe XD)
