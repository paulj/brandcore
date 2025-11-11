# Design Tokens Philosophy

## Overview

Design tokens are the atomic values that define a brand's visual language. BrandCore implements a sophisticated token system that separates **palette definition** from **semantic assignment**, enabling both design flexibility and accessibility compliance.

## Token Architecture

### Three-Layer System

```
1. PALETTE LAYER (Raw Colors)
   └─> Define pure color values with optional shading scales

2. SEMANTIC LAYER (Token Roles)
   └─> Assign meaning/purpose to palette colours

3. APPLICATION LAYER (UI Implementation)
   └─> Reference semantic tokens in components
```

This separation allows:
- Color palette changes without breaking UI
- Semantic meaning independent of specific hues
- Multiple themes from same palette
- Automated accessibility analysis
- Future aesthetic quality analysis

## 1. Palette Layer

### Colour Definition

Users define base colours in their palette with comprehensive specifications:

```ruby
# Example palette structure (stored in brand_colours.palette jsonb)
{
  colors: [
    {
      id: "ocean-blue",
      name: "Ocean Blue",
      base: {
        hex: "#0066CC",
        rgb: "0, 102, 204",
        cmyk: "100, 54, 0, 0",
        hsl: "210, 100%, 40%"
      },
      # Optional shading spectrum
      shades: [
        { stop: 50,  hex: "#E6F0FF", name: "Ocean Blue 50" },
        { stop: 100, hex: "#CCE0FF", name: "Ocean Blue 100" },
        { stop: 200, hex: "#99C2FF", name: "Ocean Blue 200" },
        { stop: 300, hex: "#66A3FF", name: "Ocean Blue 300" },
        { stop: 400, hex: "#3385FF", name: "Ocean Blue 400" },
        { stop: 500, hex: "#0066CC", name: "Ocean Blue 500" }, # Base
        { stop: 600, hex: "#0052A3", name: "Ocean Blue 600" },
        { stop: 700, hex: "#003D7A", name: "Ocean Blue 700" },
        { stop: 800, hex: "#002952", name: "Ocean Blue 800" },
        { stop: 900, hex: "#001429", name: "Ocean Blue 900" }
      ],
      # Metadata
      category: "primary", # primary, secondary, accent, neutral, semantic
      tags: ["blue", "cool", "trustworthy"]
    },
    {
      id: "slate-gray",
      name: "Slate Gray",
      base: { hex: "#64748B", rgb: "100, 116, 139", hsl: "215, 16%, 47%" },
      shades: [
        # ... full spectrum
      ],
      category: "neutral"
    }
  ]
}
```

### Shading Spectrum Generation

**User Options:**
1. **Manual definition:** User provides each shade explicitly
2. **Auto-generation:** System generates spectrum from base color
   - Lightness scale (HSL manipulation)
   - Perceptually uniform (OKLCH color space)
   - Custom algorithm selection
3. **AI-assisted generation:** AI suggests complete harmonious palettes
   - Based on brand vision/personality inputs
   - Industry-specific palette recommendations
   - Trend-aware color combinations
   - Automatic shading spectrum generation

**Additional Options:**
- Import from Tailwind config
- Import from design tool (Figma variables)

## 2. Semantic Layer (Token Roles)

### Built-in Token Roles

Semantic tokens give colors **meaning** in the UI. BrandCore provides a comprehensive set of token roles organized by purpose.

**Complete Token Inventory (~45 tokens):**
- Surface/Background: 6 tokens
- Content/Text: 7 tokens
- Border: 12 tokens
- Interactive: 6 tokens
- Semantic States: 8 tokens
- Brand Expression: 3 tokens
- Additional contextual tokens as needed

#### Surface Tokens (Elevation-based)

Surfaces use an **elevation model** where higher numbers indicate elements that float above the base:

- `surface-base` (or `surface-0`) - Base page background
- `surface-1` - First elevation (cards, panels on the page)
- `surface-2` - Second elevation (dropdowns on cards, nested panels)
- `surface-3` - Third elevation (modals, popovers, tooltips)
- `surface-overlay` - Dim overlay behind modals/drawers
- `surface-inverse` - Inverted surface (dark when main is light, vice versa)

**Rationale:** Elevation-based naming is more intuitive than primary/secondary/tertiary because it maps to the visual concept of layers "floating" above each other. Material Design and modern design systems use this approach successfully.

#### Content Tokens

**General content:**
- `content-primary` - Main text color
- `content-secondary` - Subdued text (captions, labels)
- `content-tertiary` - Placeholder/hint text
- `content-disabled` - Disabled text

**Context-specific content:**
- `content-inverse` - Text on inverse surfaces
- `content-on-interactive-primary` - Text on primary interactive elements
- `content-on-interactive-secondary` - Text on secondary interactive elements

#### Border Tokens

Borders need to work contextually with the surfaces they're on:

**Surface-specific borders:**
- `border-on-base` - Borders on base background (e.g., page dividers)
- `border-on-surface-1` - Borders on elevated cards
- `border-on-surface-2` - Borders on second-level elevation
- `border-on-surface-3` - Borders on modals/popovers

**Interactive borders:**
- `border-interactive` - Default border for interactive elements (inputs, buttons)
- `border-interactive-hover` - Hover state
- `border-interactive-focus` - Focus rings (must meet 3:1 contrast ratio)
  - **Best Practice:** Use a **single, consistent focus color** across the entire UI
  - Should work on all surface elevations and interactive element types
  - Often brand primary color or a high-contrast blue
- `border-focus-secondary` (optional) - Outer ring for double-ring focus indicator
  - Provides extra contrast on varied backgrounds
  - Typically white or very light color paired with darker inner ring
- `border-interactive-disabled` - Disabled state

**Semantic borders:**
- `border-error` - Error states
- `border-success` - Success states
- `border-warning` - Warning states
- `border-info` - Info states

**Rationale:** Borders must be considered alongside the surface they appear on for accessibility. A border that works on `surface-base` may not be visible on `surface-1`.

**Focus Ring Philosophy:**

Industry best practice is to use a **single, consistent focus ring color** across the entire interface rather than varying it per element type. This approach:

- **Creates predictable patterns:** Keyboard users learn one visual indicator for "focused state"
- **Improves accessibility:** Consistent indicator is easier to recognize and follow
- **Simplifies implementation:** One focus style to test and maintain across all contexts
- **Ensures visibility:** Single high-contrast color can be chosen to work on all backgrounds

Examples from major design systems:
- **GitHub:** Consistent blue focus ring on all interactive elements
- **Tailwind CSS:** Single blue ring (customizable but uniform)
- **Shopify Polaris:** Consistent blue focus indicator
- **Material Design:** Consistent focus indicator color

**Multi-ring Approach (Recommended):**

For maximum visibility across light and dark backgrounds, use a **double-ring focus indicator**:

```css
/* Primary button with double-ring focus */
.button-primary:focus {
  outline: 2px solid var(--border-focus-secondary); /* Outer white ring */
  outline-offset: 0px;
  box-shadow: 0 0 0 4px var(--border-interactive-focus); /* Inner brand color */
}
```

This ensures the focus indicator is visible whether the button is on a white page background or a dark footer.

**Do NOT vary focus color by:**
- Element type (primary vs. secondary button)
- Element state (success vs. error)
- Surface elevation
- Component category

The focus indicator should be the **same visual signature** regardless of what is focused.

#### Interactive Tokens
- `interactive-primary` - Primary action buttons
- `interactive-primary-hover` - Hover state
- `interactive-primary-active` - Active/pressed state
- `interactive-secondary` - Secondary actions
- `interactive-secondary-hover`
- `interactive-secondary-active`

#### Semantic State Tokens
- `semantic-info` - Informational messages
- `semantic-info-bg` - Info background
- `semantic-success` - Success messages
- `semantic-success-bg`
- `semantic-warning` - Warnings
- `semantic-warning-bg`
- `semantic-error` - Errors
- `semantic-error-bg`

#### Brand Expression Tokens
- `brand-primary` - Primary brand color (hero sections, CTA)
- `brand-secondary` - Secondary brand color
- `brand-accent` - Accent color for emphasis

### Component Token Groups

Most UI elements require **coordinated sets of tokens** that work together accessibly. Rather than assigning tokens in isolation, the system should validate these common groupings:

#### Common Component Patterns

**Buttons:**
```
Primary Button:
  Default:
    - background: interactive-primary
    - text: content-on-interactive-primary
    - border: border-interactive (optional)
  Focus:
    - focus-ring: border-interactive-focus (SAME for all buttons)
    - focus-ring-secondary: border-focus-secondary (optional outer ring)

Secondary Button:
  Default:
    - background: interactive-secondary
    - text: content-on-interactive-secondary
    - border: border-interactive
  Focus:
    - focus-ring: border-interactive-focus (SAME as primary)

Ghost/Outline Button:
  Default:
    - background: transparent or surface-N
    - text: interactive-primary
    - border: border-interactive
  Focus:
    - focus-ring: border-interactive-focus (SAME as primary)

Note: All button types use IDENTICAL focus ring styling.
```

**Input Fields:**
```
Default State:
  - background: surface-1 or surface-2
  - text: content-primary
  - border: border-interactive

Focus State:
  - background: surface-1 or surface-2
  - text: content-primary
  - border: border-interactive-focus

Error State:
  - background: surface-1 or surface-2
  - text: content-primary
  - border: border-error
```

**Cards/Panels:**
```
Card on Base:
  - background: surface-1
  - text: content-primary
  - border: border-on-surface-1 (optional)

Nested Card:
  - background: surface-2
  - text: content-primary
  - border: border-on-surface-2 (optional)
```

**Alert/Banner Components:**
```
Info Alert:
  - background: semantic-info-bg
  - text: semantic-info
  - border: border-info (optional)

Error Alert:
  - background: semantic-error-bg
  - text: semantic-error
  - border: border-error (optional)
```

#### Additional "On Surface" Content Tokens

To properly support the component patterns above, we need content tokens scoped to specific backgrounds:

- `content-on-interactive-primary` - Text on primary buttons/elements
- `content-on-interactive-secondary` - Text on secondary buttons
- `content-on-surface-inverse` - Text on inverted surfaces

These ensure text is always readable on its specific background, not just on the base surface.

### Token Assignment Interface

Users assign palette colours to semantic roles:

```ruby
# Example assignments (stored in brand_colours.token_assignments jsonb)
{
  assignments: [
    {
      token_role: "surface-primary",
      palette_colour_id: "slate-gray",
      shade: 50, # Which shade from the spectrum
      override_hex: null # Optional: override instead of using palette
    },
    {
      token_role: "interactive-primary",
      palette_colour_id: "ocean-blue",
      shade: 500
    },
    {
      token_role: "interactive-primary-hover",
      palette_colour_id: "ocean-blue",
      shade: 600
    },
    {
      token_role: "content-primary",
      palette_colour_id: "slate-gray",
      shade: 900
    }
  ]
}
```

### Theme Variants (Future)

Multiple themes from one palette:

```ruby
{
  themes: [
    {
      name: "light",
      assignments: [ ... ]
    },
    {
      name: "dark",
      assignments: [ ... ] # Different shade assignments
    }
  ]
}
```

## 3. Application Layer

### CSS Variable Generation

When rendering a brand book, generate CSS custom properties from token assignments:

```css
/* Generated from token assignments */
:root {
  /* Surface tokens (elevation-based) */
  --surface-base: #FFFFFF;
  --surface-1: #F8FAFC; /* slate-gray-50 */
  --surface-2: #F1F5F9; /* slate-gray-100 */
  --surface-3: #E2E8F0; /* slate-gray-200 */
  --surface-overlay: rgba(0, 0, 0, 0.5);
  --surface-inverse: #0F172A;

  /* Content tokens */
  --content-primary: #0F172A; /* slate-gray-900 */
  --content-secondary: #475569; /* slate-gray-600 */
  --content-tertiary: #94A3B8; /* slate-gray-400 */
  --content-disabled: #CBD5E1; /* slate-gray-300 */
  --content-inverse: #FFFFFF;
  --content-on-interactive-primary: #FFFFFF;
  --content-on-interactive-secondary: #0F172A;

  /* Border tokens */
  --border-on-base: #E2E8F0;
  --border-on-surface-1: #CBD5E1;
  --border-on-surface-2: #94A3B8;
  --border-on-surface-3: #64748B;
  --border-interactive: #94A3B8;
  --border-interactive-hover: #64748B;
  --border-interactive-focus: #0066CC; /* Uniform focus color - SAME for all elements */
  --border-focus-secondary: #FFFFFF; /* Optional outer ring for double-ring focus */
  --border-interactive-disabled: #E2E8F0;
  --border-error: #DC2626;
  --border-success: #16A34A;
  --border-warning: #D97706;
  --border-info: #0284C7;

  /* Interactive tokens */
  --interactive-primary: #0066CC; /* ocean-blue-500 */
  --interactive-primary-hover: #0052A3; /* ocean-blue-600 */
  --interactive-primary-active: #003D7A; /* ocean-blue-700 */
  --interactive-secondary: #F1F5F9; /* slate-gray-100 */
  --interactive-secondary-hover: #E2E8F0; /* slate-gray-200 */
  --interactive-secondary-active: #CBD5E1; /* slate-gray-300 */

  /* Semantic state tokens */
  --semantic-info: #0284C7;
  --semantic-info-bg: #E0F2FE;
  --semantic-success: #16A34A;
  --semantic-success-bg: #DCFCE7;
  --semantic-warning: #D97706;
  --semantic-warning-bg: #FEF3C7;
  --semantic-error: #DC2626;
  --semantic-error-bg: #FEE2E2;

  /* Brand expression */
  --brand-primary: #0066CC;
  --brand-secondary: #64748B;
  --brand-accent: #7C3AED;
}
```

### Tailwind 4 Integration

Tailwind 4 uses CSS-based configuration instead of JavaScript config files. Tokens are defined using the `@theme` directive:

```css
/* app/assets/stylesheets/brand_tokens.css */
/* Generated from brand color token assignments */

@theme {
  /* Surface tokens */
  --color-surface-base: #FFFFFF;
  --color-surface-1: #F8FAFC;
  --color-surface-2: #F1F5F9;
  --color-surface-3: #E2E8F0;
  --color-surface-overlay: rgba(0, 0, 0, 0.5);
  --color-surface-inverse: #0F172A;

  /* Content tokens */
  --color-content-primary: #0F172A;
  --color-content-secondary: #475569;
  --color-content-tertiary: #94A3B8;
  --color-content-disabled: #CBD5E1;
  --color-content-inverse: #FFFFFF;
  --color-content-on-interactive-primary: #FFFFFF;
  --color-content-on-interactive-secondary: #0F172A;

  /* Border tokens */
  --color-border-on-base: #E2E8F0;
  --color-border-on-surface-1: #CBD5E1;
  --color-border-interactive: #94A3B8;
  --color-border-interactive-hover: #64748B;
  --color-border-interactive-focus: #0066CC;
  --color-border-focus-secondary: #FFFFFF;
  --color-border-interactive-disabled: #E2E8F0;

  /* Interactive tokens */
  --color-interactive-primary: #0066CC;
  --color-interactive-primary-hover: #0052A3;
  --color-interactive-secondary: #F1F5F9;
  --color-interactive-secondary-hover: #E2E8F0;

  /* Semantic tokens */
  --color-semantic-error: #DC2626;
  --color-semantic-error-bg: #FEE2E2;
  --color-semantic-success: #16A34A;
  --color-semantic-success-bg: #DCFCE7;

  /* Brand expression */
  --color-brand-primary: #0066CC;
  --color-brand-secondary: #64748B;
  --color-brand-accent: #7C3AED;
}
```

**Note:** Tailwind 4's `@theme` directive automatically makes these colors available as utility classes:
- `bg-surface-base`, `bg-surface-1`, etc.
- `text-content-primary`, `text-content-secondary`, etc.
- `border-border-interactive`, `border-border-interactive-focus`, etc.

No JavaScript configuration needed!

Usage in markup - demonstrating three-part token system and uniform focus rings:
```html
<!-- Primary button: background + text + border + focus -->
<button class="
  bg-interactive-primary
  text-content-on-interactive-primary
  border border-interactive
  hover:bg-interactive-primary-hover
  focus:ring-4 focus:ring-border-interactive-focus
  focus:outline-none
">
  Primary Action
</button>

<!-- Secondary button: SAME focus ring as primary -->
<button class="
  bg-interactive-secondary
  text-content-on-interactive-secondary
  border border-interactive
  hover:bg-interactive-secondary-hover
  focus:ring-4 focus:ring-border-interactive-focus
  focus:outline-none
">
  Secondary Action
</button>

<!-- Ghost button: SAME focus ring -->
<button class="
  bg-transparent
  text-interactive-primary
  border border-interactive
  hover:bg-surface-1
  focus:ring-4 focus:ring-border-interactive-focus
  focus:outline-none
">
  Ghost Action
</button>

<!-- Input field: background + text + border + SAME focus ring -->
<input class="
  bg-surface-1
  text-content-primary
  border border-interactive
  focus:ring-4 focus:ring-border-interactive-focus
  focus:outline-none
  placeholder:text-content-tertiary
" />

<!-- Card on base: background + text + border -->
<div class="
  bg-surface-1
  text-content-primary
  border border-on-surface-1
  rounded-lg p-6
">
  Card content
</div>
```

## Accessibility Analysis

### WCAG Compliance Checking

For every token assignment, automatically analyze component groups (not just isolated pairs):

#### 1. Contrast Ratios

**Text-on-Background Checks (4.5:1 for normal text, 3:1 for large):**

```ruby
# Content/Surface pairings
[
  { foreground: "content-primary",   background: "surface-base",   min_ratio: 4.5 },
  { foreground: "content-primary",   background: "surface-1",      min_ratio: 4.5 },
  { foreground: "content-secondary", background: "surface-base",   min_ratio: 4.5 },
  { foreground: "content-on-interactive-primary", background: "interactive-primary", min_ratio: 4.5 },
  { foreground: "semantic-error", background: "semantic-error-bg", min_ratio: 4.5 },
  # ... all meaningful pairings
]
```

**Border-on-Background Checks (3:1 minimum for UI components - WCAG 2.1 Non-text Contrast):**

```ruby
# Border/Surface pairings
[
  { foreground: "border-on-base",       background: "surface-base", min_ratio: 3.0 },
  { foreground: "border-on-surface-1",  background: "surface-1",    min_ratio: 3.0 },
  { foreground: "border-interactive",   background: "surface-1",    min_ratio: 3.0 },
  { foreground: "border-interactive-focus", background: "surface-base", min_ratio: 3.0 },
  # ... all border contexts
]
```

**Focus Ring Validation (Critical for Keyboard Accessibility):**

The focus ring must work on ALL interactive elements and surfaces:

```ruby
# Test focus ring on every surface elevation
[
  { foreground: "border-interactive-focus", background: "surface-base",  min_ratio: 3.0 },
  { foreground: "border-interactive-focus", background: "surface-1",     min_ratio: 3.0 },
  { foreground: "border-interactive-focus", background: "surface-2",     min_ratio: 3.0 },
  { foreground: "border-interactive-focus", background: "surface-3",     min_ratio: 3.0 },

  # Test on all interactive element backgrounds
  { foreground: "border-interactive-focus", background: "interactive-primary",   min_ratio: 3.0 },
  { foreground: "border-interactive-focus", background: "interactive-secondary", min_ratio: 3.0 },
]
```

**Warning:** If focus ring fails on any surface, recommend using double-ring approach with `border-focus-secondary`.

**Component Group Validation:**

For each component pattern (button, input, card), validate the full trio:
```ruby
# Example: Primary Button validation
{
  component: "primary_button",
  tokens: {
    background: "interactive-primary",
    text: "content-on-interactive-primary",
    border: "border-interactive"
  },
  checks: [
    { pair: "text/background", ratio: 4.8, status: "pass", requirement: 4.5 },
    { pair: "border/background", ratio: 3.2, status: "pass", requirement: 3.0 }
  ],
  overall_status: "pass"
}
```

**Output:**
```ruby
{
  pair: "content-primary on surface-base",
  ratio: 18.2,
  aa_normal: "pass",      # 4.5:1
  aa_large: "pass",       # 3:1
  aaa_normal: "pass",     # 7:1
  aaa_large: "pass"       # 4.5:1
}
```

#### 2. Color Blindness Simulation

Simulate token assignments through different types of color blindness:
- Protanopia (red-blind)
- Deuteranopia (green-blind)
- Tritanopia (blue-blind)

**Check:**
- Do semantically different tokens remain distinguishable?
- Does primary CTA still stand out from background?

#### 3. Non-Color Indicators

Flag if relying solely on color for semantic meaning:
- Error states should have icons, not just red color
- Success should have confirmation text, not just green

### Accessibility Report

Generate comprehensive report with component-level analysis:

```ruby
{
  overall_score: 87, # Out of 100
  wcag_level: "AA", # AA or AAA

  # Text/Background issues
  text_issues: [
    {
      severity: "error",
      token_pair: "content-tertiary on surface-1",
      contrast_ratio: 3.8,
      required_ratio: 4.5,
      suggestion: "Use slate-gray-600 instead of slate-gray-400"
    }
  ],

  # Border/Background issues
  border_issues: [
    {
      severity: "warning",
      token_pair: "border-on-surface-1 on surface-1",
      contrast_ratio: 2.8,
      required_ratio: 3.0,
      suggestion: "Increase border color darkness by one shade"
    }
  ],

  # Component-level issues
  component_issues: [
    {
      severity: "error",
      component: "secondary_button",
      problem: "Border not distinguishable from background",
      affected_tokens: ["interactive-secondary", "border-interactive"],
      suggestion: "Use a darker border or remove border entirely"
    }
  ],

  # Color blindness issues
  color_blind_issues: [
    {
      severity: "warning",
      issue: "semantic-error and semantic-warning are similar in protanopia",
      suggestion: "Consider adding distinctive icons or patterns"
    }
  ],

  passed_checks: [
    "All primary content meets WCAG AA",
    "Interactive elements have sufficient contrast",
    "Focus indicators are visible (3:1+)",
    "All component groups are valid"
  ]
}
```

## Future: Aesthetic Quality Analysis

### Harmony Analysis

Analyze color relationships:

#### 1. Color Theory Compliance
- **Complementary:** Colors opposite on color wheel
- **Analogous:** Adjacent colors
- **Triadic:** Evenly spaced colors
- **Monochromatic:** Single hue with variations

Score palette against these schemes.

#### 2. Saturation Balance
- Check if palette has balanced saturation levels
- Flag if all colors are highly saturated (can feel overwhelming)
- Flag if all colors are desaturated (can feel flat)

#### 3. Temperature Balance
- Analyze warm vs. cool colors
- Suggest if palette skews too far in one direction

### Perceptual Uniformity

Using OKLCH or CIELAB color spaces:

- Check if shading scales have **perceptually even steps**
- Detect if middle shades appear too similar or too different
- Suggest adjustments for smoother scales

### Industry Benchmarks

Compare against well-regarded brand palettes:
- How many colors? (Most use 2-4 primaries)
- Saturation levels compared to industry leaders
- Contrast patterns in successful brands

### Trend Analysis (Future)

- Identify if palette feels "current" vs. dated
- Flag if using colors associated with specific eras
- Suggest contemporary alternatives

## Data Model Considerations

### Storage Structure

```ruby
# brand_colours table
{
  # PALETTE LAYER
  palette: {
    colors: [ ... ] # As defined above
  },

  # SEMANTIC LAYER
  token_assignments: {
    assignments: [ ... ] # As defined above
  },

  # ANALYSIS RESULTS (cached)
  accessibility_analysis: {
    last_analyzed_at: "2024-01-15T10:30:00Z",
    wcag_level: "AA",
    issues: [ ... ],
    contrast_matrix: { ... }
  },

  aesthetic_analysis: {
    last_analyzed_at: "2024-01-15T10:30:00Z",
    harmony_score: 85,
    balance_score: 72,
    suggestions: [ ... ]
  },

  # METADATA
  palette_generation_method: "manual", # or "auto", "imported"
  usage_guidelines: "text..."
}
```

### Analysis Triggers

Re-run analyses when:
- Token assignments change
- Palette colors change
- New analysis algorithms added (async job for all brands)

## User Experience

### Color Palette Editor

1. **Palette Creation Options**
   - **AI Generation:** Provide brand vision/keywords, get suggested palette
   - **Manual Creation:** Start from scratch with color picker
   - **Import:** Load from Tailwind/Figma/existing brand

2. **Add/Edit Palette Colors**
   - Color picker with live preview
   - Option to generate shading spectrum
   - Spectrum customization (number of stops, algorithm)
   - AI refinement suggestions

3. **Token Assignment Interface**
   - Visual list of all token roles
   - For each role:
     - Dropdown to select palette color
     - Dropdown to select shade
     - Live preview of assignment
     - Accessibility indicator (✓ pass, ⚠ warning, ✗ fail)
   - Preview section showing common UI patterns with current tokens

4. **Accessibility Dashboard**
   - Contrast matrix (all pairings)
   - Color blindness preview toggles
   - Issue list with fix suggestions
   - One-click "Apply suggestion" buttons

5. **Aesthetic Analysis Panel**
   - Harmony score with explanation
   - Visual representation of color relationships
   - Comparison to exemplar palettes
   - Suggestions for improvement

### Preview Components

Show token assignments in context:

```html
<!-- Example preview components -->
<div class="preview-section">
  <h3>Button Styles</h3>
  <button class="bg-interactive-primary text-content-inverse">Primary</button>
  <button class="bg-interactive-secondary text-content-primary">Secondary</button>
</div>

<div class="preview-section">
  <h3>Semantic States</h3>
  <div class="bg-semantic-info-bg text-semantic-info">Info message</div>
  <div class="bg-semantic-success-bg text-semantic-success">Success</div>
  <div class="bg-semantic-warning-bg text-semantic-warning">Warning</div>
  <div class="bg-semantic-error-bg text-semantic-error">Error</div>
</div>
```

## Implementation Phases

### Phase 1: Foundation (MVP)
- Basic palette definition (with manual colors)
- Core semantic token roles (20-30 tokens)
- Simple token assignment
- WCAG contrast checking
- CSS variable generation
- **AI-assisted palette generation** (from brand vision/prompts)

### Phase 2: Advanced Palette
- Shading spectrum generation (auto from base colours)
- Multiple algorithms (HSL, OKLCH)
- Palette import from tools (Tailwind, Figma)
- Enhanced AI suggestions with style variations

### Phase 3: Comprehensive Accessibility
- Full WCAG analysis
- Color blindness simulation
- Automated suggestions
- Accessibility score

### Phase 4: Aesthetic Analysis
- Harmony analysis
- Perceptual uniformity checks
- Industry benchmark comparison

### Phase 5: Themes & Export
- Multiple theme variants
- Export to design tools
- Token documentation generation

## Technical Stack

### Libraries/Gems to Consider

- **Color manipulation:** `color` gem for conversions and calculations
- **Contrast calculation:** Custom implementation or `wcag_color_contrast` gem
- **Color blindness simulation:** `color-blind` library or custom matrix transforms
- **OKLCH support:** May need JavaScript library (CSS Color Module 4)
- **Tailwind CSS 4:** CSS-based configuration via `@theme` directive (no JS config needed)

### Performance

- Cache analysis results (only recompute on change)
- Background jobs for expensive calculations
- Debounce live preview updates

## Open Questions for Discussion

1. Should we support **gradients** as palette items?
2. How to handle **opacity/transparency** in tokens? (e.g., `bg-surface-1/50`)
3. Should we allow **per-component overrides** of tokens?
4. Do we want **dark mode as separate theme** or **automatic inversion**?
5. Should aesthetic analysis be **opt-in** (could feel prescriptive)?
6. Should we provide **component presets** (pre-configured token groups for common patterns)?
7. How prescriptive should we be about token usage in the UI preview? Show all possible combinations or curated best practices?
8. Should users be able to **add custom token roles** beyond the built-in set?

## Architecture Decisions Made

These were discussed and decided:

1. ✅ **Elevation-based surfaces** (surface-base, surface-1, surface-2) instead of primary/secondary/tertiary
   - More intuitive and maps to visual mental model of layering

2. ✅ **Context-specific border tokens** (border-on-base, border-on-surface-1) instead of generic borders
   - Ensures borders are visible on the surfaces they're used with

3. ✅ **Three-part component validation** (background + text + border)
   - Accessibility checking must validate complete component groups, not just pairs
   - Border-on-background requires 3:1 contrast (WCAG 2.1 Non-text Contrast)

4. ✅ **Content-on-interactive tokens** (content-on-interactive-primary, etc.)
   - Ensures text on interactive elements (buttons) has proper contrast

5. ✅ **Uniform focus ring color** across all interactive elements
   - Single consistent color (border-interactive-focus) used on all buttons, inputs, links, etc.
   - Does NOT vary by element type (primary vs. secondary button use same focus ring)
   - Creates predictable visual pattern for keyboard navigation
   - Optional double-ring approach (border-focus-secondary) for extra visibility
   - Must pass 3:1 contrast on all surfaces and interactive backgrounds

## References

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Design Tokens W3C Community Group](https://www.w3.org/community/design-tokens/)
- [Tailwind Color Palette Philosophy](https://tailwindcss.com/docs/customizing-colors)
- [Material Design Color System](https://m3.material.io/styles/color/system/overview)
- [Radix Colors](https://www.radix-ui.com/colors) - Accessible color system example
