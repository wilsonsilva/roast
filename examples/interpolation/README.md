# Interpolation Example

This example demonstrates how to use Roast's interpolation feature to create dynamic workflows.

## Overview

The workflow in this example:
1. Analyzes a file and extracts its metadata
2. Extracts patterns based on the file type
3. Dynamically selects a report generation step based on the file extension
4. Outputs a completion message using the file's basename

## Interpolation Examples

The workflow demonstrates several types of interpolation:

- `{{ }}` syntax for embedding dynamic values
- Access to file metadata via expressions like `{{file_basename}}` and `{{file_ext}}`
- Dynamic step selection with `generate_report_for_{{file_ext}}`
- Shell command interpolation with `$(echo "Processing completed for file: {{file_basename}}")`

## Running the Example

To run this example with a Ruby file:

```bash
roast execute workflow.yml /path/to/some_file.rb
```

Or with a JavaScript file:

```bash
roast execute workflow.yml /path/to/some_file.js
```

The workflow will:
1. Extract the file's basename and extension
2. Store these in the workflow context
3. Dynamically choose a report generator based on file extension
4. Create a markdown report file
5. Output a completion message with the filename

## How Interpolation Works

1. When Roast processes a step name or shell command, it looks for `{{ }}` patterns
2. Expressions inside `{{ }}` are evaluated in the workflow's context using Ruby's `instance_eval`
3. This allows access to the workflow's variables, methods, and output hash
4. The evaluated expressions replace the `{{ }}` patterns in the step name or command

This makes workflows dynamic and able to respond to different inputs without code changes.