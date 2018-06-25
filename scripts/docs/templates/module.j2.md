# [docs](index.md) » {{ module.name }}
---

{{ module.doc }}
{% if module["submodules"]|length > 0 %}

## Submodules
{% for submodule in module["submodules"] %}
 * [{{ module.name }}.{{ submodule }}]({{ module.name }}.{{ submodule }}.md)
{% endfor %}
{% endif %}

## API Overview
{% for type in type_order %}
{# Considering: {{ type }} ({{ module[type]|length }}) #}
{% if module[type]|length > 0 %}
* {{ type }}s - {{ type_desc[type] }}
{% for item in module[type] %}
 * [{{ item.name }}](#{% filter lower %}{{ item.name }}{% endfilter %})
{% endfor %}
{% endif %}
{% endfor %}

## API Documentation

{% for type in type_order %}{% if module[type]|length > 0 %}
### {{ type}}s

{% for item in module[type] %}
#### [{{ item.name }}](#{% filter lower %}{{ item.name }}{% endfilter %})
| <span style="float: left;">**Signature**</span> | <span style="float: left;">`{{ item.def }}` </span>                                                          |
| -----------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| **Type**                                             | {{ item.type }} |
| **Description**                                      | {{ item.desc }} |
{% if "parameters" in item %}
| **Parameters**                                       | {{ item.parameters | join | markdown | replace("\n","") }} |
{% endif %}
{% if "returns" in item %}
| **Returns**                                          | {{ item.returns | join | markdown | replace("\n","") }} |
{% endif %}
{% if "notes" in item %}
| **Notes**                                            | {{ item.notes | join | markdown | replace("\n","") }} |
{% endif %}

{% endfor %}{% endif %}{% endfor %}