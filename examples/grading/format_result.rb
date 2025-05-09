# frozen_string_literal: true

class FormatResult < Roast::Workflow::BaseStep
  RUBRIC = {
    line_coverage: { description: "Line Coverage", weight: 0.1 },
    method_coverage: { description: "Method Coverage", weight: 0.1 },
    branch_coverage: { description: "Branch Coverage", weight: 0.3 },
    test_helpers: { description: "Test Helpers Usage", weight: 0.1 },
    mocks_and_stubs: { description: "Mocks and Stubs Usage", weight: 0.1 },
    readability: { description: "Test Readability", weight: 0.1 },
    maintainability: { description: "Test Maintainability", weight: 0.1 },
    effectiveness: { description: "Test Effectiveness", weight: 0.1 },
  }.freeze

  def call
    append_to_final_output(<<~OUTPUT)
      ========== TEST GRADE REPORT ==========
      Test file: #{workflow.file}
    OUTPUT

    format_results
    append_to_final_output("\n\n")
  end

  private

  def format_results
    format_grade

    append_to_final_output("RUBRIC SCORES:")
    workflow.output["calculate_final_grade"][:rubric_scores].each do |category, data|
      append_to_final_output("  #{RUBRIC[category][:description]} (#{(RUBRIC[category][:weight] * 100).round}% of grade):")
      append_to_final_output("    Value: #{data[:raw_value]}")
      append_to_final_output("    Score: #{(data[:score] * 10).round}/10 - \"#{data[:description]}\"")
    end
  end

  def format_grade
    letter_grade = workflow.output["calculate_final_grade"][:final_score][:letter_grade]
    celebration_emoji = letter_grade == "A" ? "🎉" : ""
    append_to_final_output(<<~OUTPUT)
      \nFINAL GRADE:
        Score: #{(workflow.output["calculate_final_grade"][:final_score][:weighted_score] * 100).round}/100
        Letter Grade: #{letter_grade} #{celebration_emoji}
    OUTPUT
  end
end
