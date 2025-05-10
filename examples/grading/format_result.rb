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
    # With HashWithIndifferentAccess, we can simply access with either syntax
    grade_data = workflow.output["calculate_final_grade"]

    unless grade_data
      return append_to_final_output("Error: Grading data not available. This may be because you're replaying the workflow from this step, but the previous step data is missing or not found in the selected session.")
    end

    format_grade(grade_data)

    # Make sure rubric_scores exists before trying to iterate over it
    unless grade_data[:rubric_scores]
      return append_to_final_output("Error: Rubric scores data not available in the workflow output.")
    end

    append_to_final_output("RUBRIC SCORES:")
    grade_data[:rubric_scores].each do |category, data|
      # Safely access RUBRIC with a fallback for potentially missing categories
      rubric_item = RUBRIC[category.to_sym] || { description: "Unknown Category", weight: 0 }

      append_to_final_output("  #{rubric_item[:description]} (#{(rubric_item[:weight] * 100).round}% of grade):")
      append_to_final_output("    Value: #{data[:raw_value] || "N/A"}")
      append_to_final_output("    Score: #{data[:score] ? (data[:score] * 10).round : "N/A"}/10 - \"#{data[:description] || "No description available"}\"")
    end
  end

  def format_grade(grade_data)
    return append_to_final_output("\nError: Final grade data not available.") unless grade_data && grade_data[:final_score]

    letter_grade = grade_data[:final_score][:letter_grade]
    celebration_emoji = letter_grade == "A" ? "🎉" : ""
    append_to_final_output(<<~OUTPUT)
      \nFINAL GRADE:
        Score: #{(grade_data[:final_score][:weighted_score] * 100).round}/100
        Letter Grade: #{letter_grade} #{celebration_emoji}
    OUTPUT
  end
end
