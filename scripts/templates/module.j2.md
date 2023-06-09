# {{ module.name }}

{{ module.doc }}
{% if module["submodules"]|length > 0 %}

---

## Submodules
{% for submodule in module["submodules"] %}
 * [{{ module.name }}.{{ submodule }}]({{ module.name }}.{{ submodule }}.md)
{% endfor %}
{% endif %}

---

## API Overview
{% for type in type_order %}
{# Considering: {{ type }} ({{ module[type]|length }}) #}
{% if module[type]|length > 0 %}
**{{ type }}s** - _{{ type_desc[type] }}_
{% for item in module[type] %}
 * [{{ item.name }}](#{{ item.name | lower | replace(" ", "-") }})
{% endfor %}

{% endif %}
{% endfor %}

---

## API Documentation

{% for type in type_order %}{% if module[type]|length > 0 %}
#### {{ type}}s

{% for item in module[type] %}

### [{{ item.name }}](#{{ item.name | lower | replace(" ", "-") }})

|                                             |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `{{ item.def }}`                                                                    |
| **Type**                                    | {{ item.type }}                                                                     |
| **Description**                             | {{ item.desc }}                                                                     |
{% if "parameters" in item %}
| **Parameters**                              | <ul>{% for parameter in item.parameters %}<li>{{ parameter | replace(" * ","") }}</li>{% endfor %}</ul> |
{% endif %}
{% if "returns" in item %}
| **Returns**                                 | <ul>{% for return in item.returns %}<li>{{ return | replace(" * ","") }}</li>{% endfor %}</ul>          |
{% endif %}
| **Notes**                                   | {% if "notes" in item %}<ul>{% for note in item.notes %}<li>{{ note | replace(" * ","") }}</li>{% endfor %}</ul>{% else %}- None{% endif %} |

---

{% endfor %}{% endif %}{% endfor %}