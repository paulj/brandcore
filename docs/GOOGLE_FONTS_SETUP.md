# Google Fonts Integration

The Typography controller integrates with Google Fonts to allow users to select fonts for their brand. This document explains how to set it up.

## Setup Options

### Configure Google Fonts API

1. **Get an API Key:**
   - Go to [Google API Console](https://console.developers.google.com/)
   - Create a new project or select an existing one
   - Enable the "Web Fonts Developer API"
   - Create credentials → API Key

2. **Add API Key to 1Password:**
   Create a 'Google Fonts API Key' item as a 'API Credentials type'. Put the API key into the 'Credential' field.

3. **The service will automatically:**
   - Fetch fonts from the API
   - Cache results for 24 hours
   - Fall back to static data if API fails

### Populate Static Font File

To reduce API calls, a Static Data file can be populated.

1. **Download the font metadata:**
   ```bash
   make cache-google-fonts
   ```

2. **Commit the file:**
   ```bash
   git add config/google_fonts.json
   git commit -m "Add Google Fonts metadata"
   ```

3. **The service will:**
   - Use the static file if API is unavailable
   - Update the file periodically by running the rake task

## How It Works

### Font Selection

- Users can search fonts by name or category
- Fonts are displayed with live previews
- Selected fonts are stored in the `primary_typeface` JSONB field

### Font Suggestions

The system suggests fonts based on brand vision:
- **Brand Personality** traits (traditional → serif, modern → sans-serif, etc.)
- **Brand Positioning** keywords
- **Mission/Vision** statements

### Font Categories

Fonts are categorized as:
- **Serif** - Traditional, elegant brands
- **Sans-serif** - Modern, clean brands (default)
- **Display** - Bold, creative brands
- **Handwriting** - Artisan, personal brands
- **Monospace** - Technical, developer brands

## Service Architecture

- `GoogleFontsService` - Fetches and caches font data
- `FontSuggestionService` - Suggests fonts based on brand vision
- `Brand::TypographyController` - Handles font selection endpoints
- `FontPickerController` (Stimulus) - UI interactions for font picker

## API Endpoints

- `GET /brands/:brand_id/typography/search_fonts?q=query` - Search fonts
- `GET /brands/:brand_id/typography/suggest_fonts` - Get suggestions
- `GET /brands/:brand_id/typography/fonts_by_category?category=serif` - Get by category
