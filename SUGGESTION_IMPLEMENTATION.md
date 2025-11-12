# Suggestion Persistence Implementation

## Overview

This document describes the implementation of persistent AI suggestions in BrandCore. The system allows AI-generated suggestions to be saved to the database, chosen by users, or archived, building up a history of what works and what doesn't.

## Architecture

### Database Schema

A single polymorphic `Suggestion` model handles all types of suggestions across different brand components:

```ruby
class Suggestion < ApplicationRecord
  belongs_to :suggestionable, polymorphic: true
  enum status: { pending: 0, chosen: 1, archived: 2 }

  # Fields:
  # - suggestionable_type, suggestionable_id (polymorphic association)
  # - field_name (string) - e.g., "mission_statement", "keywords"
  # - content (jsonb) - stores suggestion data (text or structured)
  # - status (integer) - pending/chosen/archived
  # - chosen_at, archived_at (datetime)
  # - metadata (jsonb) - for future extensibility
end
```

### Content Structure

Suggestions store different data types based on field:

**Simple text fields** (mission_statement, vision_statement, category):
```json
{
  "text": "Your brand's mission statement..."
}
```

**Array fields** (keywords, target_markets, target_audience):
```json
{
  "keywords": ["keyword1", "keyword2", "keyword3"]
}
```

**Complex fields** (brand_personality):
```json
{
  "traits": ["Innovative", "Friendly"],
  "tone": ["Professional", "Approachable"]
}
```

## Implementation

### 1. Model Setup

**Suggestion Model** (`app/models/suggestion.rb`):
- Polymorphic association to any brand component
- Enum status (pending/chosen/archived)
- Scopes for filtering (`for_field`, `recent_first`)
- Methods: `choose!`, `archive!`, `archive_siblings`

**BrandVision Model** (updated):
```ruby
has_many :suggestions, as: :suggestionable, dependent: :destroy
```

### 2. Background Jobs

All 7 AI generation jobs have been updated to persist suggestions:

- `GenerateMissionStatementsJob`
- `GenerateVisionStatementJob`
- `GenerateKeywordsJob`
- `GenerateTargetAudienceJob`
- `GenerateBrandPersonalityJob`
- `GenerateCategorySuggestionJob`
- `GenerateTargetMarketsJob`

Each job now:
1. Generates suggestions via AI service
2. Creates `Suggestion` records in database
3. Broadcasts persisted suggestions (not raw data)

Example pattern:
```ruby
def perform(brand_id)
  # ... generate candidates ...

  # Persist suggestions
  suggestions = persist_suggestions(brand_vision, candidates)

  # Broadcast persisted suggestions
  broadcast_suggestions(brand, suggestions)
end

private

def persist_suggestions(brand_vision, candidates)
  candidates.map do |candidate|
    brand_vision.suggestions.create!(
      field_name: "mission_statement",
      content: { text: candidate },
      status: :pending
    )
  end
end
```

### 3. Controllers

**VisionController** (`app/controllers/brand/vision_controller.rb`):
- Updated `update` action to handle `suggestion_id` parameter
- When a suggestion is chosen, calls `suggestion.choose!` which:
  - Marks suggestion as chosen
  - Archives all other suggestions for that field

**SuggestionsController** (`app/controllers/suggestions_controller.rb`) - NEW:
- `archive` action for marking suggestions as archived
- Handles both individual suggestions and group suggestions
- Re-renders the appropriate suggestions partial after archiving

### 4. Routes

Added suggestion routes:
```ruby
resources :suggestions, only: [] do
  member do
    patch :archive
  end
end
```

### 5. Views

Updated views fall into two categories:

**Individual Suggestions** (mission_statement, vision_statement):
- Display array of suggestions
- Each suggestion has:
  - Clickable area to choose the suggestion
  - Archive button (X) that appears on hover
- On page load: renders existing pending suggestions

**Group Suggestions** (keywords, brand_personality, etc):
- Display single suggestion with multiple options
- "Clear suggestions" button to archive the entire group
- On page load: renders most recent pending suggestion

Example structure:
```erb
<div id="mission_statement_suggestions">
  <% if suggestions.any? %>
    <% suggestions.each_with_index do |suggestion, index| %>
      <%= form_with model: brand.brand_vision, ... do |f| %>
        <%= f.hidden_field :mission_statement, value: suggestion.text_content %>
        <%= hidden_field_tag :suggestion_id, suggestion.id %>

        <button type="submit">
          <!-- Suggestion content -->
        </button>

        <%= button_to archive_suggestion_path(suggestion), method: :patch %>
          <i class="fa-solid fa-times"></i>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
</div>
```

## User Flow

### Generating Suggestions

1. User clicks "AI Help" button
2. Controller enqueues background job
3. Job generates suggestions via OpenAI
4. Job creates `Suggestion` records (status: pending)
5. Job broadcasts via Turbo Streams
6. View displays suggestions from database

### Choosing a Suggestion

1. User clicks on a suggestion
2. Form submits with `suggestion_id` parameter
3. Controller updates the field value
4. Controller calls `suggestion.choose!`:
   - Updates suggestion status to `chosen`
   - Sets `chosen_at` timestamp
   - Archives all other suggestions for that field
5. View refreshes showing saved value

### Archiving a Suggestion

1. User clicks "X" button on suggestion
2. `SuggestionsController#archive` is called
3. Suggestion status set to `archived`
4. View re-renders showing remaining suggestions

### Persistence Across Page Loads

When a page loads:
- Field partials render existing pending suggestions
- Suggestions persist until chosen or archived
- Users can navigate away and return without losing suggestions

## Views Completed

✅ **Fully Implemented:**
- Mission Statement
- Vision Statement
- Keywords

⚠️ **Partially Implemented:**
- Brand Personality (job updated, view needs update)
- Target Audience (job updated, view needs update)
- Target Markets (job updated, view needs update)
- Category (job updated, view needs update)

## Remaining Work

### 1. Update Remaining Views

The following views need to be updated to use the persisted suggestion pattern:

- `app/views/brand/vision/_brand_personality_suggestions.html.erb`
- `app/views/brand/vision/_brand_personality_field.html.erb`
- `app/views/brand/vision/_target_audience_suggestions.html.erb`
- `app/views/brand/vision/_target_audience_field.html.erb`
- `app/views/brand/vision/_target_markets_suggestions.html.erb`
- `app/views/brand/vision/_target_markets_field.html.erb`
- `app/views/brand/vision/_category_suggestions.html.erb`
- `app/views/brand/vision/_category_field.html.erb`

Follow the same pattern as keywords (group suggestions) since they all work with arrays/objects.

### 2. Testing

The database migration needs to be run:
```bash
bin/rails db:migrate
```

Then test the flow:
1. Generate suggestions
2. Refresh page (should persist)
3. Choose a suggestion (should archive others)
4. Archive a suggestion (should remove from list)

### 3. Edge Cases

Consider handling:
- What if user generates suggestions multiple times?
- Should we limit the number of pending suggestions per field?
- Should archived suggestions be viewable in a history?
- Auto-archive old suggestions after X days?

### 4. Future Enhancements

- History view showing chosen/archived suggestions
- "Undo" functionality for recently archived suggestions
- Suggestion quality feedback (thumbs up/down)
- Learn from user preferences over time
- Bulk actions (archive all, regenerate all)

## Database Migration

Remember to run the migration:
```bash
bin/rails db:migrate
```

The migration creates the `suggestions` table with:
- Polymorphic association columns
- JSONB content field for flexibility
- Indexes for performance
- Status enum for state management
- Timestamps for tracking history

## Benefits

1. **Persistence**: Suggestions survive page refreshes
2. **History**: Track what works and what doesn't
3. **Learning**: Build a dataset of user preferences
4. **Flexibility**: Single model handles all suggestion types
5. **Clean State**: Chosen suggestions auto-archive siblings
6. **User Control**: Archive unwanted suggestions explicitly

## Technical Notes

- Uses Turbo Streams for real-time updates
- Polymorphic associations keep the data model clean
- JSONB provides flexibility for different data structures
- Enum status provides clear state management
- Scopes make querying easy and readable
