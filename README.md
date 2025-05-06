![image](https://github.com/user-attachments/assets/39589441-d15a-452b-b51c-3bf28f470308)

# Roast

A convention-oriented framework for creating structured AI workflows, maintained by the Augmented Engineering team at Shopify.

## Why you should use Roast

Roast provides a structured, declarative approach to building AI workflows with:

- **Convention over configuration**: Define workflows using simple YAML files with step-by-step instructions
- **Built-in tools**: Ready-to-use tools for file operations, search, and AI interactions
- **Parallel execution**: Run multiple steps concurrently to speed up workflows
- **Extensive instrumentation**: Monitor and track workflow execution, AI calls, and tool usage ([see instrumentation documentation](docs/INSTRUMENTATION.md))
- **Step isolation**: Each step runs in its own context with configurable AI models and parameters
- **Ruby integration**: Native Ruby support with a clean, extensible architecture

## What does it look like?

Here's a simple workflow that analyzes test files:

```yaml
name: analyze_tests
tools:
  - Roast::Tools::ReadFile
  - Roast::Tools::Grep

steps:
  - read_test_file
  - analyze_coverage
  - generate_report

analyze_coverage:
  model: gpt-4-mini
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
roast execute workflow.yml target_file.rb
```

### Understanding Workflows

In Roast, workflows maintain a single conversation with the AI model throughout execution. Each step represents one or more user-assistant interactions within this conversation, with optional tool calls. All steps share context through:

1. A continuous conversation history 
2. A shared output hash that acts as a "scratchpad" for passing data between steps

This means steps can reference results from previous steps and build upon earlier work.

### Command Line Options

#### Basic Options
- `-c, --concise`: Use concise output templates
- `-o, --output FILE`: Save results to a file  
- `-v, --verbose`: Show output from all steps as they execute
- `-s, --subject FILE`: Specify a subject file to analyze

#### Target Option (`-t, --target`)

The target option is highly flexible and accepts several formats:

**File paths:**
```bash
roast execute workflow.yml -t path/to/file.rb
```

**Glob patterns:**
```bash
roast execute workflow.yml -t "**/*_test.rb"
```

**Shell command execution with $(...):**
```bash
roast execute workflow.yml -t "$(find . -name '*.rb' -mtime -1)"
```

**Git integration examples:**
```bash
# Process changed test files
roast execute workflow.yml -t "$(git diff --name-only HEAD | grep _test.rb)"

# Process staged files  
roast execute workflow.yml -t "$(git diff --cached --name-only)"
```

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

Available in templates:
- `response`: The AI's response for this step
- `workflow`: Access to the workflow object
- `workflow.output`: The shared hash containing results from all previous steps
- `workflow.file`: Current file being processed
- All workflow configuration options

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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
