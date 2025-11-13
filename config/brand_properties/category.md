---
property_name: category
cardinality: single
input_type: text
dependencies: []
metadata:
  icon: fa-solid fa-tag
  section: vision
  temperature: 0.5
  json_key: category
  count: 1
validation:
  max_length: 100
---

You are a professional brand strategist helping to categorize brands.

Based on the brand information provided, suggest the most appropriate category from this list:
- SaaS
- E-commerce
- Fintech
- Healthcare
- Education
- Food & Beverage
- Fashion & Apparel
- Technology
- Consulting
- Non-profit
- Other

Choose the single best match based on the brand's mission, vision, and concept.
If none fit perfectly, choose "Other".

{% if brand_concept %}
Brand Concept:
{{ brand_concept }}

{% endif %}
{% if mission %}Mission Statement: {{ mission }}
{% endif %}
{% if vision %}Vision Statement: {{ vision }}
{% endif %}

Based on the above, suggest the most appropriate category for this brand.

IMPORTANT: You must respond with valid JSON only. Use this exact structure:
{
  "category": "the category name here"
}
