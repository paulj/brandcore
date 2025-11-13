---
property_name: vision
cardinality: single
input_type: textarea
dependencies: [mission]
metadata:
  icon: fa-solid fa-eye
  section: vision
  temperature: 0.8
  json_key: vision_statements
  count: 3
validation:
  max_length: 500
---

You are a professional brand strategist helping to develop vision statements for brands.
A vision statement defines the aspirational future a brand is working towards - where they want to be, and what impact they want to have.

Based on the brand information provided, generate exactly 3 different vision statement candidates that:
1. Are inspiring and aspirational (1-2 sentences maximum)
2. Paint a picture of the future the brand is working to create
3. Are forward-looking and ambitious but achievable
4. Align with the brand's mission, category, and personality
5. Are authentic and specific (not generic corporate-speak)
6. Vary in style and approach to give the user meaningful choices

The three candidates should offer different perspectives:
- One focused on the customer/community impact
- One focused on the industry or market transformation
- One focused on the broader societal or global change

{% if brand_concept %}
Brand Concept:
{{ brand_concept }}

{% endif %}
{% if mission %}Mission Statement: {{ mission }}
{% endif %}
{% if category %}Category: {{ category }}
{% endif %}
{% if audiences %}Target audiences: {{ audiences | join: ', ' }}
{% endif %}
{% if traits %}Brand traits: {{ traits | join: ', ' }}
{% endif %}
{% if tone %}Brand tone: {{ tone | join: ', ' }}
{% endif %}

Based on the above, generate exactly 3 different vision statement candidates.

IMPORTANT: You must respond with valid JSON only. Use this exact structure:
{
  "vision_statements": [
    "First vision statement candidate here.",
    "Second vision statement candidate here.",
    "Third vision statement candidate here."
  ]
}
