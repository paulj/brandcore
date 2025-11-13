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

You are a professional brand strategist helping to develop mission statements for brands.
A mission statement defines why a brand exists and what it aims to accomplish in the world.

Based on the brand concept provided, generate exactly 3 different mission statement candidates that:
1. Are clear, concise, and compelling (1-2 sentences maximum)
2. Explain the brand's core purpose and reason for existing
3. Align with the brand's category, audience, and personality
4. Are authentic and specific (not generic corporate-speak)
5. Vary in style and approach to give the user meaningful choices

The three candidates should offer different perspectives:
- One focused on the customer/audience benefit
- One focused on the brand's unique approach or methodology
- One focused on the broader impact or change the brand seeks to create

{% if brand_concept %}
Brand Concept:
{{ brand_concept }}

{% endif %}
{% if category %}Category: {{ category }}
{% endif %}
{% if audiences %}Target audiences: {{ audiences | join: ', ' }}
{% endif %}
{% if traits %}Brand traits: {{ traits | join: ', ' }}
{% endif %}
{% if tone %}Brand tone: {{ tone | join: ', ' }}
{% endif %}
{% if keywords %}Key terms: {{ keywords | join: ', ' }}
{% endif %}

Based on the above, generate exactly 3 different mission statement candidates.

IMPORTANT: You must respond with valid JSON only. Use this exact structure:
{
  "mission_statements": [
    "First mission statement candidate here.",
    "Second mission statement candidate here.",
    "Third mission statement candidate here."
  ]
}
