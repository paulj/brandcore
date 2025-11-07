# BrandCore - Development Context

## Project Overview

BrandCore is a step-by-step brand creation tool that guides users through building a complete, professional brand identity from absolute zero. The tool produces a structured brand profile and web-accessible brand book that can be shared and referenced.

**Tech Stack:** Rails 8.1, PostgreSQL, Tailwind CSS, Turbo, Stimulus, PaperTrail (versioning), StoreModel (JSONB structuring)

**Spelling Convention:** This project uses Australian English spelling (e.g., "colour" not "color", "organisation" not "organization"). This applies to all model names, database columns, UI text, and documentation.

## Core Philosophy

The brand book IS the interface. Rather than a separate creation flow followed by brand book generation, users work directly within their brand book, providing:
- Immediate visual context for all brand decisions
- Natural navigation between sections
- Real-time preview of the brand as it develops
- Progressive enhancement as components are completed (brand book adopts the brand's colors, fonts, logo)

## Seven Brand Components

BrandCore guides users through seven core brand elements in a logical sequence:

1. **Name** - Brand identifier with domain availability checking, working names auto-generated if needed
2. **Brand Vision** - Strategic foundation (mission, vision, values, positioning, audience, personality)
3. **Logo Uses** - Comprehensive logo documentation and usage guidelines
4. **Brand Language** - Verbal identity (tone, messaging, taglines, vocabulary)
5. **Colour Palette** - Visual color system with semantic design tokens (see `docs/DESIGN_TOKENS.md`)
6. **Typography** - Type system (typefaces, hierarchy, weights, usage)
7. **UI Language** - Design system components and patterns

## Architecture Overview

### Directory Structure

- **`/app/models/`** - Domain models (User, Brand, 7 component models, color system)
- **`/app/controllers/`** - BrandsController, SessionsController, PasswordsController
- **`/app/presenters/`** - Data transformation layer (CSS, design tokens, exports)
- **`/config/routes.rb`** - REST routing
- **`/db/schema.rb`** - Database schema
- **`/spec/models/`** - RSpec model tests
- **`/docs/`** - Comprehensive documentation (DATA_MODEL.md, DESIGN_TOKENS.md, BRAND_CREATION_PROCESS.md)

### Key Models & Relationships

**Core Entities:**
- `User` - bcrypt authentication, has many brands through brand_memberships
- `Brand` - Root entity with slug-based URLs, versioned with PaperTrail
- `Session` - Browser session tracking
- `BrandMembership` - Role-based access (owner, editor, viewer)

**Seven Components (1-to-1 with Brand):**
- `BrandName`, `BrandVision`, `BrandLogo`, `BrandLanguage`
- `BrandColourScheme`, `BrandTypography`, `BrandUI`
- Each has `completed` boolean and `completed_at` timestamp
- All versioned with PaperTrail

**Color System (Normalized):**
- `BrandColourScheme` (parent) → has many `PaletteColour` → has many `PaletteShade`
- `TokenAssignment` - Maps semantic token roles to palette colors
- Accessibility & aesthetic analysis cached in JSONB fields

### Data Architecture Patterns

1. **Presenter Layer** - Data transformation in presenters, not models
2. **Hybrid JSONB/Normalized** - Normalized tables for integrity, JSONB for cached analysis
3. **StoreModel for JSONB** - Structured JSONB attributes with validations using StoreModel gem
   - Complex JSONB fields are modeled as separate classes (e.g., `CoreValue` for `BrandVision.core_values`)
   - Provides type safety, validations, and accessor methods for JSONB arrays/objects
   - Example: `attribute :core_values, CoreValue.to_array_type`
4. **One-to-One Components** - Each brand has exactly one of each component
5. **Version History** - PaperTrail gem tracks all changes with whodunnit
6. **Working Names** - Auto-generated (Adjective + Noun) if user doesn't provide name
7. **Slug-Based URLs** - Human-readable URLs instead of IDs

### Controllers & Routes

- `BrandsController` - Index, show, new, create, edit, update, destroy
- `SessionsController` - Rate-limited login (10/3 minutes), logout
- `PasswordsController` - Password reset flow with 1-hour token expiration
- Authentication via `Authentication` concern (signed cookies, thread-local Current object)

## Testing
- Tests, Linting and Quality Security checks are run via `make`
- RSpec for model/integration tests
- Rubocop for style, Brakeman for security
- Run tests: `bundle exec rspec` or `make spec`

## Key Documentation

- **`docs/DATA_MODEL.md`** - Comprehensive domain model and database design
- **`docs/DESIGN_TOKENS.md`** - Color system philosophy and implementation
- **`docs/BRAND_CREATION_PROCESS.md`** - User workflow and feature specifications
- **`docs/JSONB_VS_NORMALIZED.md`** - Architecture decision rationale
- **`docs/TODO.md`** - Project roadmap

## Development Guidelines

### Brand Creation Flow
1. User creates brand (can be unauthenticated - creates account simultaneously)
2. Brand auto-generates working name if not provided
3. System creates owner membership + all 7 component records in transaction
4. User enters brand book with all pages in skeleton state
5. User completes components in any order (flexible, non-linear)
6. Brand book progressively adopts the brand's identity as components complete

### Design Token System
Three-layer architecture (palette → semantic tokens → application):
- **Palette Layer** - Base colors with optional shading spectrums (50-900 scale)
- **Semantic Layer** - Token roles (surface, content, interactive, etc.)
- **Application Layer** - CSS custom properties generated from assignments

This ensures brand consistency, accessibility compliance, and future-proof design tool integrations.

### Security & Authentication
- bcrypt password hashing
- Signed httponly cookies with same_site:lax
- Rate limiting on login attempts
- Password reset tokens expire after 1 hour
- Session tracking with IP and user agent

## Current Development Status

**Branch:** `claude-build`

**Recent Work:**
- Brand model implementation with working name generation
- BrandsController with full CRUD operations
- Brand book view structure with sidebar navigation
- Brand Vision component with auto-save functionality
- Core values editor with StoreModel (name, description, icon)
- Color system model specs
- Authentication flow

**Key Implementation Patterns:**
- Transaction-based record creation
- Presenter pattern for data exports
- Version history via PaperTrail
- Role-based access control
- StoreModel for structured JSONB attributes
- Turbo Streams for auto-save functionality
- Stimulus controllers for interactive components