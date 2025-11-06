# BrandCore: Brand Creation Tool

## Overview

BrandCore is a step-by-step brand creation tool that guides users through building a complete, professional brand identity from absolute zero. The tool produces a structured brand profile and web-accessible brand book that can be shared and referenced.

## Philosophy

The tool is designed to meet users wherever they are in their brand journey:
- Users starting from scratch are guided through each step systematically
- Users with existing brand elements (e.g., a name or logo) can skip completed steps
- The process is flexible yet comprehensive, ensuring no critical brand element is overlooked

## Brand Components

BrandCore helps users define and document seven core brand elements in a logical sequence:

### 1. Name
The foundational identifier for the brand. This is the starting point for brands beginning from zero, or can be provided if already established.

**Working Names:**
When a user creates a new brand without providing a name, the system auto-generates a working name using a haiku-style approach: `[Adjective] [Noun]` (e.g., "Bold Canvas", "Swift Harbor"). Users can keep this working name throughout the brand development process and finalize it later—even after completing the Brand Vision. This allows for non-linear workflow where vision can inform name selection.

**Features:**
- Domain availability lookup for proposed names
- Real-time checking of common TLDs (.com, .io, etc.)
- Alternative suggestions if preferred domains are taken
- Track names considered and rationale for final choice

### 2. Brand Vision
The strategic foundation of the brand - **this comes before visual identity** as it informs all design decisions:
- Mission statement
- Vision statement
- Core values
- Brand positioning
- Target audience
- Brand personality

### 3. Logo Uses
Comprehensive documentation of logo variations and usage guidelines (informed by brand vision):
- Primary logo
- Secondary/alternate versions
- Minimum size requirements
- Clear space rules
- Acceptable and unacceptable uses
- File formats and when to use each

### 4. Brand Language
The verbal identity and communication style:
- Tone of voice
- Key messaging pillars
- Taglines or slogans
- Vocabulary guidelines (words to use/avoid)
- Writing style guidelines

### 5. Colour Palette
The visual colour system with sophisticated design token architecture.

**See `docs/DESIGN_TOKENS.md` for comprehensive philosophy and implementation.**

Key features:
- **Palette Layer:** Define base colors with optional shading spectrums (50-900 scale)
- **Semantic Layer:** Assign colors to semantic token roles (surface, content, interactive, etc.)
- **Accessibility Analysis:** Automated WCAG contrast checking, colour blindness simulation
- **Aesthetic Analysis:** Harmony scoring, perceptual uniformity, industry benchmarking
- **Dynamic Application:** CSS custom properties generated from token assignments

This three-layer system (palette → semantic tokens → application) ensures:
- Brand consistency across all touchpoints
- Accessibility compliance by design
- Easy theme variations (light/dark mode)
- Future-proof for design tool integrations

### 6. Typography
The type system for the brand:
- Primary typeface(s)
- Secondary typeface(s)
- Type hierarchy
- Font weights and styles
- Usage guidelines (headlines, body text, etc.)
- Web font specifications

### 7. UI Language
Design system components and patterns:
- Button styles
- Form elements
- Iconography
- Spacing system
- Grid system
- Component patterns
- Interactive states

## User Workflow

### The Brand Book IS the Interface

Rather than a separate creation flow followed by brand book generation, **users work directly within their brand book**. This approach provides:

- Immediate visual context for all brand decisions
- Natural navigation between sections
- Real-time preview of the brand as it develops
- Elimination of the "creation vs. viewing" mental model

### Initial Experience

1. **Brand Creation**
   - User creates a new brand
   - System generates a working name (e.g., "Clear Compass") if none provided
   - User immediately enters their live brand book

2. **Skeleton State**
   - All seven brand book pages are visible but show in skeleton state
   - Each page clearly indicates "Not yet completed"
   - Pages use neutral styling until brand elements are defined

3. **Persistent Sidebar**
   - Always-visible checklist showing completion status:
     ```
     ☐ Name
     ☐ Brand Vision
     ☐ Logo Uses
     ☐ Brand Language
     ☐ Colour Palette
     ☐ Typography
     ☐ UI Language
     ```
   - Clicking any item navigates to that page
   - Visual indicators show: Complete, In Progress, Not Started

### Working on Components

1. **Page-Based Editing**
   - Each brand book page has both view and edit modes
   - Edit mode provides:
     - Educational context and prompts
     - Input fields appropriate to the component
     - Real-time preview of changes
     - Examples and inspiration
   - Auto-save as user works

2. **Progressive Enhancement**
   - As components are completed, the brand book itself transforms
   - Colour palette → brand book adopts those colors
   - Typography → brand book uses those fonts
   - Logo → appears in header/navigation
   - The brand book becomes a living example of the brand

### Navigation & Flexibility

- Users can navigate freely between any pages
- No forced linear workflow
- Can partially complete sections and return later
- Changes are versioned (see history tracking below)

## Brand Book Output

The final brand book is a comprehensive, web-based reference that includes:

- **Interactive Table of Contents**
- **Visual Preview** of all brand elements
- **Copy-friendly** colour codes and specifications
- **Downloadable Assets** (logos, fonts where licensed)
- **Share Options** (public URL, password-protected, team access)
- **Version History** (track changes over time)
- **Export Options** (PDF, Figma integration potential)

## Dynamic Brand Book Styling

As the brand is built, the brand book interface itself adopts the brand's identity through Tailwind CSS custom properties:

```css
/* Brand-specific CSS variables */
:root {
  --brand-primary: #000000;      /* Updated when colour palette defined */
  --brand-secondary: #666666;
  --brand-accent: #0066CC;
  --brand-font-heading: system-ui; /* Updated when typography defined */
  --brand-font-body: system-ui;
}
```

This creates a meta experience where:
- The tool demonstrates the brand by becoming the brand
- Users see real-world application of their choices
- The brand book serves as both documentation and live example

## Technical Considerations

### Data Structure
See `docs/DATA_MODEL.md` for comprehensive database design.

Key aspects:
- Multi-brand support (brands as independent entities with multiple users)
- Version history via PaperTrail gem
- Asset storage for uploads (logos, fonts, images)
- Published vs. draft states
- **Presenter layer** for data transformation (CSS, JSON, exports)

### Architecture
- **Models:** Data integrity, validation, persistence
- **Presenters:** Data transformation for different output formats
  - `StylesheetPresenter` - CSS variables
  - `TailwindPresenter` - Tailwind 4 @theme blocks
  - `AccessibilityReportPresenter` - WCAG reports
  - `JsonExportPresenter` - Design tool exports
- Clean separation enables easy addition of new export formats

### User Experience Priorities
- Mobile-responsive throughout creation and viewing
- Fast, intuitive navigation
- Helpful, educational content without being overwhelming
- Beautiful presentation that reflects the quality brands aspire to
- Collaboration features (multi-user editing potential)

## Core Features

**Included from launch:**
- AI-assisted palette generation (from brand vision/personality inputs)
- Domain availability checking for name selection
- Automated WCAG accessibility analysis
- Version history and change tracking (PaperTrail)
- Multi-user collaboration with role-based access
- Real-time brand book preview with progressive styling

## Future Enhancements

Potential features for future iterations:
- Advanced collaboration tools (comments, review workflows)
- Brand consistency checker across external assets
- Deep integration with design tools (Figma sync, Adobe)
- Industry-specific templates and starting points
- Brand asset library management
- AI-powered brand consistency audits
