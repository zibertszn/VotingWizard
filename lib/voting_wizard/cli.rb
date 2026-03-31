# frozen_string_literal: true

require "optparse"

module VotingWizard
  class CLI
    MENU_ACTIONS = {
      "1" => :add_option,
      "2" => :vote,
      "3" => :show_results,
      "4" => :show_winner,
      "5" => :exit_cli
    }.freeze

    def initialize(stdin: $stdin, stdout: $stdout, stderr: $stderr)
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @poll = nil
    end

    def run(argv = [])
      options = parse_options(argv)
      return 0 if options[:help]

      setup_poll(options)
      interactive_loop
    rescue OptionParser::ParseError => e
      @stderr.puts e.message
      @stderr.puts "Use --help to see available options."
      1
    rescue ArgumentError, Error => e
      @stderr.puts e.message
      1
    end

    private

    def parse_options(argv)
      options = {help: false, options: []}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: voting_wizard [options]"

        opts.on("-qQUESTION", "--question=QUESTION", "Poll question") do |question|
          options[:question] = question
        end

        opts.on("-oOPTION", "--option=OPTION", "Poll option (can be used multiple times)") do |option|
          options[:options] << option
        end

        opts.on("-h", "--help", "Show help") do
          @stdout.puts opts
          options[:help] = true
        end
      end

      parser.parse!(argv)
      options
    end

    def setup_poll(options)
      question = options[:question] || prompt("Enter poll question:")
      @poll = Poll.new(question)

      seeded_options = options[:options].dup
      seeded_options = prompt_options if seeded_options.empty?
      seeded_options.each { |option| @poll.add_option(option) }
    end

    def prompt_options
      @stdout.puts "Enter poll options one per line. Submit an empty line to finish."

      options = []
      loop do
        option = prompt("Option #{options.length + 1}:")
        break if option.empty?

        options << option
      end

      raise InvalidOptionError, "At least one option is required" if options.empty?

      options
    end

    def interactive_loop
      loop do
        print_menu
        action = MENU_ACTIONS[prompt("Choose an action:")]

        unless action
          @stderr.puts "Unknown action. Please choose 1-5."
          next
        end

        break if action == :exit_cli

        send(action)
      rescue Error, ArgumentError => e
        @stderr.puts e.message
      end

      @stdout.puts "Goodbye!"
      0
    end

    def add_option
      option = prompt("New option:")
      @poll.add_option(option)
      @stdout.puts "Option added: #{option.strip}"
    end

    def vote
      user = prompt("User name:")
      show_options
      option = prompt("Vote for option:")
      @poll.vote(user: user, option: option)
      @stdout.puts "Vote accepted for #{user.strip}."
    end

    def show_results
      @stdout.puts "Results for: #{@poll.question}"
      @poll.results.each do |option, votes|
        percentage = format("%.2f", @poll.percentage_for(option))
        @stdout.puts "- #{option}: #{votes} vote(s) (#{percentage}%)"
      end
      @stdout.puts "Total votes: #{@poll.total_votes}"
    end

    def show_winner
      winner = @poll.winner

      if winner
        @stdout.puts "Winner: #{winner}"
      else
        @stdout.puts "No winner yet. There may be no votes or there is a tie."
      end
    end

    def print_menu
      @stdout.puts
      @stdout.puts "Poll: #{@poll.question}"
      @stdout.puts "1. Add option"
      @stdout.puts "2. Vote"
      @stdout.puts "3. Show results"
      @stdout.puts "4. Show winner"
      @stdout.puts "5. Exit"
    end

    def show_options
      @stdout.puts "Available options:"
      @poll.options.each do |option|
        @stdout.puts "- #{option.text}"
      end
    end

    def prompt(message)
      @stdout.puts message
      @stdin.gets&.chomp.to_s
    end
  end
end
