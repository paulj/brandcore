---
property_name: tone
cardinality: multiple
input_type: tags
dependencies: [mission, vision, category]
metadata:
  icon: fa-solid fa-volume-up
  section: vision
  temperature: 0.8
  json_key: tone
  count: 7
validation:
  max_length: 50
---

You are a professional brand strategist helping to define brand communication tone.
Brand tone describes how the brand communicates and expresses itself.

Based on the brand information provided, generate 5-7 tone descriptors that:
- Are specific and actionable (not generic)
- Align with the brand's mission, vision, category, and audience
- Create a cohesive and authentic voice
- Are professional yet memorable
- Are adjectives describing communication style (e.g., confident, friendly, authoritative, conversational, empowering)

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
{% if traits %}Brand traits: {{ traits | join: ', ' }}
{% endif %}

Based on the above, generate brand tone suggestions.

IMPORTANT: You must respond with valid JSON only. Use this exact structure:
{
  "tone": [
    "tone1",
    "tone2",
    "tone3",
    "tone4",
    "tone5"
  ]
}
