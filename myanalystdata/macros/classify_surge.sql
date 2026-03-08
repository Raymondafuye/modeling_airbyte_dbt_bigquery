{% macro classify_surge(surge_column) %}
    case
        when {{ surge_column }} is null then 'no_surge'
        when {{ surge_column }} <= 1.0 then 'no_surge'
        when {{ surge_column }} <= 2.0 then 'low_surge'
        when {{ surge_column }} <= 5.0 then 'medium_surge'
        when {{ surge_column }} <= 10.0 then 'high_surge'
        else 'extreme_surge'
    end
{% endmacro %}
