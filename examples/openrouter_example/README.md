# OpenRouter Example

This example demonstrates how to use OpenRouter with Roast to access models from different providers through a single API.

## Setup

1. Sign up for an account at [OpenRouter](https://openrouter.ai/)
2. Get your API key from the OpenRouter dashboard
3. Set the API key as an environment variable:
   ```bash
   export OPENROUTER_API_KEY=your_api_key_here
   ```

## Running the Example

```bash
# Run without a specific target (general analysis)
roast execute workflow.yml

# Run with a specific file to analyze
roast execute workflow.yml path/to/your/file.txt
```

## How it Works

This example configures Roast to use OpenRouter as the API provider:

```yaml
api_provider: openrouter
api_token: $(echo $OPENROUTER_API_KEY)
model: anthropic/claude-3-haiku-20240307
```

The workflow consists of two steps:
1. `analyze_input`: Analyzes the provided content (or generates general insights if no target is provided)
2. `generate_response`: Creates a structured response based on the analysis

## Available Models

When using OpenRouter, you can access models from multiple providers by specifying the fully qualified model name, including the provider prefix. Some examples:

- `anthropic/claude-3-opus-20240229`
- `anthropic/claude-3-sonnet-20240229`
- `meta/llama-3-70b-instruct`
- `google/gemini-1.5-pro-latest`
- `mistral/mistral-large-latest`

Check the [OpenRouter documentation](https://openrouter.ai/docs) for the complete list of supported models.