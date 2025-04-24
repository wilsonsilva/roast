# frozen_string_literal: true

require "spec_helper"
require "json-schema"
require "yaml"
require "json"

RSpec.describe(Roast::Workflow::Validator) do
  let(:schema_path) { File.join(Dir.pwd, "schema/workflow.json") }
  let(:valid_yaml_path) { File.join(Dir.pwd, "spec/fixtures/valid_workflow.yml") }
  let(:invalid_yaml_path) { File.join(Dir.pwd, "spec/fixtures/invalid_workflow.yml") }
  let(:valid_yaml) { File.read(valid_yaml_path) }
  let(:invalid_yaml) { File.read(invalid_yaml_path) }

  describe "#initialize" do
    it "initializes with valid YAML" do
      expect { Roast::Workflow::Validator.new(valid_yaml) }.not_to(raise_error)
    end

    it "raises error when YAML is invalid" do
      yaml = "name: - test"
      expect { Roast::Workflow::Validator.new(yaml) }.to(raise_error(Psych::SyntaxError))
    end
  end

  describe "#valid?" do
    context "with valid YAML that matches schema" do
      it "returns true" do
        validator = Roast::Workflow::Validator.new(valid_yaml)
        expect(validator.valid?).to(be(true))
      end
    end

    context "with valid YAML that doesn't match schema" do
      it "returns false" do
        validator = Roast::Workflow::Validator.new(invalid_yaml)
        expect(validator.valid?).to(be(false))
      end
    end

    context "with empty YAML" do
      it "returns false" do
        yaml = ""
        validator = Roast::Workflow::Validator.new(yaml)
        expect(validator.valid?).to(be(false))
      end
    end
  end

  describe "#errors" do
    it "returns empty array when YAML is valid" do
      validator = Roast::Workflow::Validator.new(valid_yaml)
      validator.valid?
      expect(validator.errors).to(be_empty)
    end

    it "returns validation errors when YAML doesn't match schema" do
      validator = Roast::Workflow::Validator.new(invalid_yaml)
      validator.valid?
      expect(validator.errors).not_to(be_empty)
      expect(validator.errors.first).to(include("steps"))
    end
  end
end
