{% macro calculate_net_revenue(amount_input, fee_input) %}
    {{ amount_input }} - {{ fee_input }}
{% endmacro %}