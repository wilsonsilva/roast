Extract some patterns about this file and return in json format like this:

<json>
{
  "code_patterns": {
    "class_structure": {
      "name": "Calculator",
      "instance_variables": ["@memory"],
      "method_count": 7,
      "method_types": {
        "constructor": ["initialize"],
        "operations": ["add", "subtract", "multiply", "divide"],
        "accessors": ["memory"],
        "utility": ["clear"]
      }
    },
    "error_handling": {
      "techniques": ["conditional raise", "zero check"],
      "examples": ["raise \"Division by zero!\" if number.zero?"]
    },
    "design_patterns": {
      "state": "Uses instance variable to maintain calculator state",
      "command": "Each operation method modifies the internal state"
    }
  }
}
</json>