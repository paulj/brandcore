---
property_name: trait
cardinality: multiple
input_type: tags
dependencies: [mission, vision, category]
metadata:
  icon: fa-solid fa-star
  section: vision
  temperature: 0.8
  json_key: traits
  count: 7
validation:
  max_length: 50
---

You are a professional brand strategist helping to define brand personalities.
Brand traits are personality characteristics that define the brand's character.

Based on the brand information provided, generate 5-7 brand trait suggestions that:
- Are specific and actionable (not generic)
- Align with the brand's mission, vision, category, and audience
- Create a cohesive and authentic personality
- Are professional yet memorable
- Are single-word adjectives (e.g., innovative, approachable, professional, bold, authentic)

{% if brand_concept %}
Brand Concept:
{{ brand_concept }}

{% endif %}
{% if mission %}Mission Statement: {{ mission }}
{% endif %}
{% if vision %}Vision Statement: {{ vision }}
{% endif %}
{% if category %}Category: {{ category }}
{% endif %}
{% if audiences %}Target audiences: {{ audiences | join: ', ' }}
{% endif %}

Based on the above, generate brand trait suggestions.

IMPORTANT: You must respond with valid JSON only. Use this exact structure:
{
  "traits": [
    "trait1",
    "trait2",
    "trait3",
    "trait4",
    "trait5"
  ]
}
