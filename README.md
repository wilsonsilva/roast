![image](https://github.com/user-attachments/assets/39589441-d15a-452b-b51c-3bf28f470308)

# Roast

A convention-oriented framework for creating structured AI workflows, maintained by the Augmented Engineering team at Shopify.

## Why you should use Roast

Roast provides a structured, declarative approach to building AI workflows with:

- **Convention over configuration**: Define powerful workflows using simple YAML configuration files and prompts written in markdown (with ERB support)
- **Built-in tools**: Ready-to-use tools for file operations, search, and AI interactions
- **Ruby integration**: When prompts aren't enough, write custom steps in Ruby using a clean, extensible architecture
- **Shared context**: Each step shares its conversation transcript with its parent workflow by default
- **Step customization**: Steps can be fully configured with their own AI models and parameters.
- **Session replay**: Rerun previous sessions starting at a specified step to speed up development time
- **Parallel execution**: Run multiple steps concurrently to speed up workflow execution
- **Function caching:**: Flexibly cache the results of tool function calls to speed up workflows
- **Extensive instrumentation**: Monitor and track workflow execution, AI calls, and tool usage ([see instrumentation documentation](docs/INSTRUMENTATION.md))

## What does it look like?

Here's a simple workflow that analyzes test files:

```yaml
name: analyze_tests
# Default model for all steps
model: gpt-4o-mini
tools:
  - Roast::Tools::ReadFile
  - Roast::Tools::Grep

steps:
  - read_test_file
  - analyze_coverage
  - generate_report

# Step-specific model overrides the global model
analyze_coverage:
  model: gpt-4-turbo
  json: true
```

Each step can have its own prompt file (e.g., `analyze_coverage/prompt.md`) and configuration. Steps can be run in parallel by nesting them in arrays:

```yaml
steps:
  - prepare_data
  - 
    - analyze_code_quality
    - check_test_coverage
    - verify_documentation
  - generate_final_report
```

## How to use Roast

1. Create a workflow YAML file defining your steps and tools
2. Create prompt files for each step (e.g., `step_name/prompt.md`)
3. Run the workflow:

```bash
# With a target file
roast execute workflow.yml target_file.rb

# Or for a targetless workflow (API calls, data generation, etc.)
roast execute workflow.yml
```

### Understanding Workflows

In Roast, workflows maintain a single conversation with the AI model throughout execution. Each step represents one or more user-assistant interactions within this conversation, with optional tool calls. Steps naturally build upon each other through the shared context.

#### Step Types

Roast supports several types of steps:

1. **Standard step**: References a directory containing at least a `prompt.md` and optional `output.txt` template. This is the most common type of step. 
  ```yaml
  steps:
    - analyze_code
  ```

  As an alternative to a directory, you can also implement a custom step as a Ruby class, optionally extending `Roast::Workflow::BaseStep`.
  
  In the example given above, the script would live at `workflow/analyze_code.rb` and should contain a class named `AnalyzeCode` with an initializer that takes a workflow object as context, and a `call` method that will be invoked to run the step. The result of the `call` method will be stored in the `workflow.output` hash.


2. **Parallel steps**: Groups of steps executed concurrently
   ```yaml
   steps:
     - 
       - analyze_code_quality
       - check_test_coverage
   ```

3. **Command execution step**: Executes shell commands directly
   ```yaml
   steps:
     - rubocop: $(bundle exec rubocop -A)
   ```
   This will execute the command and store the result in the workflow output hash under the key name (`rubocop` in this example).

4. **Raw prompt step**: Simple text prompts for the model without tools
   ```yaml
   steps:
     - Summarize the changes made to the codebase.
   ```
   This creates a simple prompt-response interaction without tool calls or looping. It's detected by the presence of spaces in the step name and is useful for summarization or simple questions at the end of a workflow.

#### Data Flow Between Steps

Roast handles data flow between steps in two primary ways:

1. **Conversation Context (Implicit)**: The LLM naturally remembers the entire conversation history, including all previous prompts and responses. In most cases, this is all you need for a step to reference and build upon previous results. This is the preferred approach for most prompt-oriented workflows.

2. **Output Hash (Explicit)**: Each step's result is automatically stored in the `workflow.output` hash using the step name as the key. This programmatic access is mainly useful when:
   - You need to perform non-LLM transformations on data
   - You're writing custom output logic
   - You need to access specific values for presentation or logging

For typical AI workflows, the continuous conversation history provides seamless data flow without requiring explicit access to the output hash. Steps can simply refer to previous information in their prompts, and the AI model will use its memory of the conversation to provide context-aware responses.

### Command Line Options

#### Basic Options
- `-o, --output FILE`: Save results to a file instead of outputting to STDOUT 
- `-c, --concise`: Use concise output templates (exposed as a boolean flag on `workflow`)
- `-v, --verbose`: Show output from all steps as they execute
- `-r, --replay STEP_NAME`: Resume a workflow from a specific step, optionally with a specific session timestamp

#### Session Replay

The session replay feature allows you to resume workflows from specific steps, saving time during development and debugging:

```bash
# Resume from a specific step
roast execute workflow.yml -r step_name

# Resume from a specific step in a specific session
roast execute workflow.yml -r 20250507_123456_789:step_name
```

Sessions are automatically saved during workflow execution. Each step's state, including the conversation transcript and output, is persisted to a session directory. The session directories are organized by workflow name and file, with timestamps for each run.

This feature is particularly useful when:
- Debugging specific steps in a long workflow
- Iterating on prompts without rerunning the entire workflow
- Resuming after failures in long-running workflows

Sessions are stored in the `.roast/sessions/` directory in your project. Note that there is no automatic cleanup of session data, so you might want to periodically delete old sessions yourself.

#### Target Option (`-t, --target`)

The target option is highly flexible and accepts several formats:

**Single file path:**
```bash
roast execute workflow.yml -t path/to/file.rb

# is equivalent to
roast execute workflow.yml path/to/file.rb
```

**Directory path:**
```bash
roast execute workflow.yml -t path/to/directory

# Roast will run on the directory as a resource
```

**Glob patterns:**
```bash
roast execute workflow.yml -t "**/*_test.rb"

# Roast will run the workflow on each matching file
```

**URL as target:**
```bash
roast execute workflow.yml -t "https://api.example.com/data"

# Roast will run the workflow using the URL as a resource
```

**API configuration (Fetch API-style):**
```bash
roast execute workflow.yml -t '{
  "url": "https://api.example.com/resource",
  "options": {
    "method": "POST",
    "headers": {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${API_TOKEN}"
    },
    "body": {
      "query": "search term",
      "limit": 10
    }
  }
}'

# Roast will recognize this as an API configuration with Fetch API-style format
```

**Shell command execution with $(...):**
```bash
roast execute workflow.yml -t "$(find . -name '*.rb' -mtime -1)"

# Roast will run the workflow on each file returned (expects one per line)
```

**Git integration examples:**
```bash
# Process changed test files
roast execute workflow.yml -t "$(git diff --name-only HEAD | grep _test.rb)"

# Process staged files  
roast execute workflow.yml -t "$(git diff --cached --name-only)"
```

#### Targetless Workflows

Roast also supports workflows that don't operate on a specific pre-defined set of target files:

**API-driven workflows:**
```yaml
name: API Integration Workflow
tools:
  - Roast::Tools::ReadFile
  - Roast::Tools::WriteFile
  
# Dynamic API token using shell command
api_token: $(cat ~/.my_token)

# Option 1: Use a targetless workflow with API logic in steps
steps:
  - fetch_api_data  # Step will make API calls
  - transform_data
  - generate_report

# Option 2: Specify an API target directly in the workflow
target: '{
  "url": "https://api.example.com/resource",
  "options": {
    "method": "GET",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}'

steps:
  - process_api_response
  - generate_report
```

**Data generation workflows:**
```yaml
name: Generate Documentation
tools:
  - Roast::Tools::WriteFile
steps:
  - generate_outline
  - write_documentation
  - create_examples
```

These targetless workflows are ideal for:
- API integrations
- Content generation
- Report creation
- Interactive tools
- Scheduled automation tasks

#### Global Model Configuration

You can set a default model for all steps in your workflow by specifying the `model` parameter at the top level:

```yaml
name: My Workflow
model: gpt-4o-mini  # Will be used for all steps unless overridden
```

Individual steps can override this setting with their own model parameter:

```yaml
analyze_data:
  model: anthropic:claude-3-haiku  # Takes precedence over the global model
```

#### Dynamic API Tokens

Roast allows you to dynamically fetch API tokens using shell commands directly in your workflow configuration:

```yaml
# This will execute the shell command and use the result as the API token
api_token: $(print-token --key)

# Or a simpler example for demonstration:
api_token: $(echo $OPENAI_API_KEY)
```

This makes it easy to use environment-specific tokens without hardcoding credentials, especially useful in development environments or CI/CD pipelines.

### Template Output with ERB

Each step can have an `output.txt` file that uses ERB templating to format the final output. This allows you to customize how the AI's response is processed and displayed.

Example `step_name/output.txt`:
```erb
<% if workflow.verbose %>
Detailed Analysis:
<%= response %>
<% else %>
Summary: <%= response.lines.first %>
<% end %>

Files analyzed: <%= workflow.file %>
Status: <%= workflow.output['status'] || 'completed' %>
```

This is an example of where the `workflow.output` hash is useful - formatting output for display based on data from previous steps.

Available in templates:
- `response`: The AI's response for this step
- `workflow`: Access to the workflow object 
- `workflow.output`: The shared hash containing results from all steps when you need programmatic access
- `workflow.file`: Current file being processed (or `nil` for targetless workflows)
- All workflow configuration options

For most workflows, you'll mainly use `response` to access the current step's results. The `workflow.output` hash becomes valuable when you need to reference specific data points from previous steps in your templates or for conditional display logic.

## Advanced Features

### Instrumentation

Roast provides extensive instrumentation capabilities using ActiveSupport::Notifications. You can monitor workflow execution, track AI model usage, measure performance, and integrate with external monitoring systems. [Read the full instrumentation documentation](docs/INSTRUMENTATION.md).

### Custom Tools

You can create your own tools using the [Raix function dispatch pattern](https://github.com/OlympiaAI/raix-rails?tab=readme-ov-file#use-of-toolsfunctions). Custom tools should be placed in `.roast/initializers/` (subdirectories are supported):

```ruby
# .roast/initializers/tools/git_analyzer.rb
module MyProject
  module Tools
    module GitAnalyzer
      extend self

      def self.included(base)
        base.class_eval do
          function(
            :analyze_commit,
            "Analyze a git commit for code quality and changes",
            commit_sha: { type: "string", description: "The SHA of the commit to analyze" },
            include_diff: { type: "boolean", description: "Include the full diff in the analysis", default: false }
          ) do |params|
            GitAnalyzer.call(params[:commit_sha], params[:include_diff])
          end
        end
      end

      def call(commit_sha, include_diff = false)
        Roast::Helpers::Logger.info("🔍 Analyzing commit: #{commit_sha}\n")
        
        # Your implementation here
        commit_info = `git show #{commit_sha} --stat`
        commit_info += "\n\n" + `git show #{commit_sha}` if include_diff
        
        commit_info
      rescue StandardError => e
        "Error analyzing commit: #{e.message}".tap do |error_message|
          Roast::Helpers::Logger.error(error_message + "\n")
        end
      end
    end
  end
end
```

Then include your tool in the workflow:

```yaml
tools:
  - MyProject::Tools::GitAnalyzer
```

The tool will be available to the AI model during workflow execution, and it can call `analyze_commit` with the appropriate parameters.

### Project-specific Configuration

You can extend Roast with project-specific configuration by creating initializers in `.roast/initializers/`. These are automatically loaded when workflows run, allowing you to:

- Add custom instrumentation
- Configure monitoring and metrics
- Set up project-specific tools
- Customize workflow behavior

Example structure:
```
your-project/
  ├── .roast/
  │   └── initializers/
  │       ├── metrics.rb
  │       ├── logging.rb
  │       └── custom_tools.rb
  └── ...
```

## Installation

```bash
$ gem install roast
```

Or add to your Gemfile:

```ruby
gem 'roast'
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake` to run the tests and linter. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
