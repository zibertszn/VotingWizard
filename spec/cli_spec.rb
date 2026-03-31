# frozen_string_literal: true

require "stringio"
require "voting_wizard"

RSpec.describe VotingWizard::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  describe "#run" do
    it "runs an interactive voting session" do
      stdin = StringIO.new(<<~INPUT)
        Favorite language?
        Ruby
        Python

        2
        Ivan
        Ruby
        3
        4
        5
      INPUT

      exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run

      expect(exit_code).to eq(0)
      expect(stdout.string).to include("Results for: Favorite language?")
      expect(stdout.string).to include("- Ruby: 1 vote(s) (100.00%)")
      expect(stdout.string).to include("Winner: Ruby")
      expect(stderr.string).to eq("")
    end

    it "supports bootstrapping from command line options" do
      stdin = StringIO.new("5\n")

      exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run(
        ["--question", "Best language?", "--option", "Ruby", "--option", "Python"]
      )

      expect(exit_code).to eq(0)
      expect(stdout.string).to include("Poll: Best language?")
      expect(stderr.string).to eq("")
    end

    it "prints validation errors to stderr" do
      stdin = StringIO.new(<<~INPUT)
        Favorite language?

      INPUT

      exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run

      expect(exit_code).to eq(1)
      expect(stderr.string).to include("At least one option is required")
    end
  end
end
