# frozen_string_literal: true

class CalculateFinalGrade < Roast::Workflow::BaseStep
  attr_accessor :llm_analysis

  WEIGHTS = {
    line_coverage: 0.1,
    method_coverage: 0.1,
    branch_coverage: 0.3,
    test_helpers: 0.1,
    mocks_and_stubs: 0.1,
    readability: 0.1,
    maintainability: 0.1,
    effectiveness: 0.1,
  }.freeze

  def call
    @llm_analysis = workflow.output["generate_grades"].merge(workflow.output["analyze_coverage"])
    weighted_sum = WEIGHTS.sum do |criterion, weight|
      score = llm_analysis[criterion.to_s]["score"].to_f / 10.0
      score * weight
    end

    {
      final_score: {
        weighted_score: weighted_sum,
        letter_grade: calculate_letter_grade(weighted_sum),
      },
      rubric_scores: calculate_rubric_scores,
    }
  end

  private

  def calculate_letter_grade(score)
    case score
    when 0.9..1.0
      "A"
    when 0.8...0.9
      "B"
    when 0.7...0.8
      "C"
    when 0.6...0.7
      "D"
    else
      "F"
    end
  end

  def calculate_rubric_scores
    scores = {}

    WEIGHTS.each_key do |criterion|
      raw_score = llm_analysis[criterion.to_s]["score"].to_f
      normalized_score = raw_score / 10.0

      scores[criterion] = {
        raw_value: raw_score,
        score: normalized_score,
        description: llm_analysis[criterion.to_s]["justification"],
        weighted_score: normalized_score * WEIGHTS[criterion],
      }
    end

    scores
  end
end
