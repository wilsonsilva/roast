# API Workflow Example

This example demonstrates a targetless workflow that interacts with APIs rather than operating on specific files.

## Structure

The workflow consists of three steps that work together to create a complete API integration process:

1. `fetch_api_data` - Simulates fetching data from a weather API and returns a structured JSON response
2. `transform_data` - Processes the JSON data into a human-readable markdown format 
3. `generate_report` - Creates a polished report with recommendations based on the weather data

## Running the Example

To run this example, you need to have a valid API token. The example is configured to fetch a token using a shell command:

```yaml
# Dynamic API token using shell command
api_token: $(print-token --key)
```

You can modify this to use your own token source, such as:

```yaml
# Using an environment variable
api_token: $(echo $OPENAI_API_KEY)

# Or a direct value (not recommended for production)
api_token: $(echo "sk-your-actual-token")
```

Then run the workflow:

```bash
# Run the targetless workflow
roast execute examples/api_workflow/workflow.yml

# Save the output to a file
roast execute examples/api_workflow/workflow.yml -o weather_report.md
```

## How Targetless Workflows Work

Targetless workflows operate without a specific target file. This is useful for:

- API integrations
- Content generation
- Data analysis
- Report creation
- Interactive tools

Unlike file-based workflows that process each target separately, targetless workflows run once and can retrieve their own data sources (like API calls) or generate content from scratch.

## Workflow Definition

```yaml
name: API Integration Workflow
# Default model for all steps
model: gpt-4o-mini

tools:
  - Roast::Tools::ReadFile
  - Roast::Tools::Grep
  - Roast::Tools::WriteFile

steps:
  - fetch_api_data
  - transform_data
  - generate_report

# Tool configurations for API calls (no need to specify model here since it uses global model)
fetch_api_data:
  print_response: true
```

## Creating Your Own Targetless Workflows

To create your own targetless workflow:

1. Create a workflow YAML file without a `target` parameter
2. Define the steps your workflow will execute
3. Create prompt files for each step
4. Run the workflow with `roast execute your_workflow.yml`

Your steps can use the workflow's `output` hash to pass data between them, just like in file-based workflows.