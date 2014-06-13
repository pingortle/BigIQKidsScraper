require 'rubygems'

require 'json'
require 'nokogiri'   
require 'open-uri'
require 'optparse'
require 'ostruct'

module BigIQKidsScraper
  module Globals
    GRADES = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth']
    GRADE_RANGE = 1..(GRADES.count)

    def self.grade_hash(enumerable)
      Hash[GRADE_RANGE.zip enumerable]
    end
  end

  class Options
    def self.output_options
      [:plaintext, :json]
    end

    def self.parse(args)
      options = OpenStruct.new
      options.output_formats = [] << self.output_options.first

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: scrape.rb [--(json|plaintext)]"
        opts.separator ""
        opts.separator "Specific options:"

        self.output_options.each do |opt|
          default = opt == self.output_options.first ? " (Default)" : ""
          opts.on("--" + opt.to_s, "Use #{opt.to_s} as the output format." + default) do
            options.output_formats = [opt]
          end
        end

        opts.on("--all", "Generate output in all formats.") do
          options.output_formats = (options.output_formats self.output_options).uniq.to_a
        end

        opts.on("-h", "--help", "Show this message.") do
          puts opts
          exit
        end
      end

      opt_parser.parse!(args)
      options
    end
  end

  class SpellingWords
    URLS = Globals.grade_hash Globals::GRADES.map {|grade| "http://www.bigiqkids.com/SpellingVocabulary/Lessons/wordlistSpelling#{grade}Grade.shtml"}

    attr_reader :grade, :url

    def initialize(grade)
      @grade = grade
      @url = URLS[grade]
      @cache = nil
    end

    def scrape_words
      page = Nokogiri::HTML(open(@url))

      @cache = @cache || page.css('table tr td a')
      .select {|x| x.text.split(' ').count == 1}
      .map {|x| x.text.downcase}
    end
  end
end

def wordlist_to_file(wordlist)
  filename = "grade#{wordlist.grade}.wordlist"
  File.open(filename, 'w') do |file|
    wordlist.scrape_words.each do |word|
      file.puts word
    end
  end
  puts "\tCreated #{filename}"
end

def wordlist_to_json(wordlist)
  filename = "grade#{wordlist.grade}_wordlist.json"
  File.open(filename, 'w') do |file|
    file.puts({
      grade: wordlist.grade,
      kind: "spelling",
      words: wordlist.scrape_words,
    }.to_json)
  end
  puts "\tCreated #{filename}"
end

options = BigIQKidsScraper::Options.parse(ARGV)

TEMP_DIR = "tmp"

GRADES_HASH = BigIQKidsScraper::Globals.grade_hash BigIQKidsScraper::Globals::GRADES

puts "Welcome to the BigIQKids.com scraper!"
Dir.mkdir(File.join(Dir.pwd, TEMP_DIR)) unless Dir.exists? TEMP_DIR

Dir.chdir(TEMP_DIR) do
  BigIQKidsScraper::Globals::GRADE_RANGE.each do |grade|
    spelling_words = BigIQKidsScraper::SpellingWords.new grade

    puts "Scraping #{GRADES_HASH[grade]} Grade..."
    wordlist_to_file(spelling_words) if options.output_formats.include? :plaintext
    wordlist_to_json(spelling_words) if options.output_formats.include? :json
  end
end
puts "Finished!"
