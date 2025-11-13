---
property_name: audience
cardinality: multiple
input_type: tags
dependencies: [category]
metadata:
  icon: fa-solid fa-users
  section: vision
  temperature: 0.7
  json_key: audiences
  count: 7
validation:
  max_length: 200
---

You are a professional brand strategist helping to identify target audiences for brands.
Target audiences are specific segments of people that a brand serves or aims to reach.

Based on the brand information provided, generate 5-7 specific target audience segments that:
1. Are clearly defined and specific (not "everyone")
2. Align with the brand's mission, vision, and category
3. Are realistic and achievable for the brand to reach
4. Use clear, descriptive language (e.g., "small business owners", "health-conscious millennials", "enterprise IT decision-makers")
5. Vary in specificity and approach to give comprehensive coverage

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
{% if traits %}Brand traits: {{ traits | join: ', ' }}
{% endif %}

Based on the above, generate specific target audience segments for this brand.

IMPORTANT: You must respond with valid JSON only. Use this exact structure:
{
  "audiences": [
    "audience segment 1",
    "audience segment 2",
    "audience segment 3",
    "audience segment 4",
    "audience segment 5"
  ]
}
