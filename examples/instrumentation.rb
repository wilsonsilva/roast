# frozen_string_literal: true

# Demonstration of how to use the Roast instrumentation hooks
# This file would typically be placed in PROJECT_ROOT/.roast/initializers/
# for automatic loading during workflow execution

# Example: Log all workflow and step events
ActiveSupport::Notifications.subscribe(/roast\.workflow\./) do |name, start, finish, _id, payload|
  duration = finish - start

  case name
  when "roast.workflow.start"
    puts "\n🚀 Workflow starting: #{payload[:name]}"
    puts "   Path: #{payload[:workflow_path]}"
    puts "   Options: #{payload[:options]}"
  when "roast.workflow.complete"
    status = payload[:success] ? "✅ Successfully" : "❌ With errors"
    puts "\n#{status} completed workflow in #{duration.round(2)} seconds"
  end
end

# Example: Track step execution times
ActiveSupport::Notifications.subscribe(/roast\.step\./) do |name, start, finish, _id, payload|
  duration = finish - start

  case name
  when "roast.step.start"
    puts "\n  ▶️ Step starting: #{payload[:step_name]}"
  when "roast.step.complete"
    puts "  ✅ Step completed: #{payload[:step_name]} (#{duration.round(3)}s)"
  when "roast.step.error"
    puts "  ❌ Step failed: #{payload[:step_name]}"
    puts "     Error: #{payload[:error]} - #{payload[:message]}"
  end
end

# Example: Monitor AI interactions
ActiveSupport::Notifications.subscribe(/roast\.chat_completion\./) do |name, start, finish, _id, payload|
  case name
  when "roast.chat_completion.start"
    puts "\n  🤖 AI request starting (model: #{payload[:model]})"
    puts "     Parameters: #{payload[:parameters].inspect}" if payload[:parameters].any?
  when "roast.chat_completion.complete"
    duration = finish - start
    puts "  🤖 AI request completed in #{duration.round(2)}s (execution time: #{payload[:execution_time].round(2)}s)"
    puts "     Response size: #{payload[:response_size]} characters"
  when "roast.chat_completion.error"
    puts "  🤖 AI request failed: #{payload[:error]} - #{payload[:message]}"
    puts "     Execution time: #{payload[:execution_time].round(2)}s"
  end
end

# Example: Track tool executions
ActiveSupport::Notifications.subscribe(/roast\.tool\./) do |name, _start, _finish, _id, payload|
  case name
  when "roast.tool.execute"
    puts "\n  🔧 Executing tool: #{payload[:function_name]}"
  when "roast.tool.complete"
    puts "  🔧 Tool completed: #{payload[:function_name]} (#{payload[:execution_time].round(3)}s)"
    puts "     Cache enabled: #{payload[:cache_enabled]}"
  when "roast.tool.error"
    puts "  🔧 Tool failed: #{payload[:function_name]}"
    puts "     Error: #{payload[:error]} - #{payload[:message]}"
    puts "     Execution time: #{payload[:execution_time].round(3)}s"
  end
end

# In a Shopify-specific initializer (e.g., .roast/initializers/monorail.rb),
# you could replace these logging examples with actual Monorail tracking:
#
# ActiveSupport::Notifications.subscribe("roast.workflow.start") do |name, start, finish, id, payload|
#   Roast::Support::Monorail.track_command("run", {
#     "workflow_path" => payload[:workflow_path],
#     "name" => payload[:name]
#   })
# end
