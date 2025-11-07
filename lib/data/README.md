# Trait Embeddings Cache

This directory contains pre-computed OpenAI embeddings for known brand traits.

## Generating the Cache

To generate the embeddings cache, you need an OpenAI API key:

```bash
export OPENAI_API_KEY='sk-your-api-key-here'
rake brand_color_palette:generate_trait_embeddings
```

This will:
- Generate embeddings for all 20+ known traits
- Save them to `trait_embeddings.json`
- Cost approximately $0.0004 (less than 1 cent)
- Take about 3-5 seconds to complete

## Cache File Format

The cache is a JSON file mapping trait names to their embedding vectors:

```json
{
  "innovative": [0.123, -0.456, 0.789, ...],
  "trustworthy": [-0.321, 0.654, -0.987, ...],
  ...
}
```

Each embedding has 1536 dimensions (for `text-embedding-3-small` model).

## Why Cache?

By pre-computing and committing the embeddings:
- The app works without requiring `OPENAI_API_KEY` for known traits
- No API calls needed for known traits (zero cost)
- Faster startup and operation
- API key only needed for mapping arbitrary/unknown traits

## Testing Trait Mapping

Test how arbitrary traits map to known traits:

```bash
rake brand_color_palette:test_trait_mapping['inventive']
# => Maps to: 'innovative'

rake brand_color_palette:test_trait_mapping['dependable']
# => Maps to: 'reliable'
```
