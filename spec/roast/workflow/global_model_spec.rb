# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe("Global Model Parameter") do
  describe "in WorkflowExecutor" do
    let(:workflow_path) { fixture_file_path("workflow_with_global_model.yml") }
    let(:workflow) { instance_double(Roast::Workflow::BaseWorkflow, output: {}, final_output: "", output_file: nil) }
    let(:step_class) { Roast::Workflow::BaseStep }
    let(:step) { instance_double(step_class, model: nil) }

    before do
      # Create a temporary workflow file with global model
      File.write(workflow_path, {
        "name" => "Workflow with Global Model",
        "model" => "gpt-4o-mini",
        "steps" => ["test_step"],
      }.to_yaml)

      allow(step_class).to(receive(:new).and_return(step))
      allow(step).to(receive(:model=))
      allow(workflow).to(receive(:output))
    end

    after do
      File.delete(workflow_path) if File.exist?(workflow_path)
    end

    it "applies global model to steps without specific model" do
      config_hash = YAML.load_file(workflow_path)
      context_path = File.dirname(workflow_path)

      executor = Roast::Workflow::WorkflowExecutor.new(workflow, config_hash, context_path)

      # Call the private setup_step method
      executor.send(:setup_step, step_class, "test_step", context_path)

      # Verify model was set to the global model
      expect(step).to(have_received(:model=).with("gpt-4o-mini"))
    end

    it "step-specific model overrides global model" do
      # Add step-specific configuration
      config_hash = YAML.load_file(workflow_path).merge({
        "test_step" => {
          "model" => "local-model",
        },
      })

      context_path = File.dirname(workflow_path)

      executor = Roast::Workflow::WorkflowExecutor.new(workflow, config_hash, context_path)

      # Call the private setup_step method
      executor.send(:setup_step, step_class, "test_step", context_path)

      # Verify step-specific model takes precedence
      expect(step).to(have_received(:model=).with("local-model"))
    end
  end
end
