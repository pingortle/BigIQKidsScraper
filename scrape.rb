require 'rubygems'

require 'json'
require 'nokogiri'   
require 'open-uri'
require 'optparse'
require 'ostruct'

module BigIQKidsScraper
  GRADES = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth']

  class Options
    def self.output_options
      [:plaintext, :json]
    end

    def self.parse(args)
      options = OpenStruct.new
      options.output = self.output_options.first

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: scrape.rb [--(json|plaintext)]"
        opts.separator ""
        opts.separator "Specific options:"

        self.output_options.each do |opt|
          default = opt == self.output_options.first ? " (Default)" : ""
          opts.on("--" + opt.to_s, "Use #{opt.to_s} as the output format." + default) do
            options.output = opt
          end
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
    URLS = GRADES.map {|grade| "http://www.bigiqkids.com/SpellingVocabulary/Lessons/wordlistSpelling#{grade}Grade.shtml"}

    attr_reader :grade, :url

    def initialize(grade)
      @grade = grade
      @url = URLS[grade - 1]
    end

    def scrape_words
      page = Nokogiri::HTML(open(@url))

      page.css('table tr td a')
      .select {|x| x.text.split(' ').count == 1}
      .map {|x| x.text.downcase}
    end
  end
end

def wordlist_to_file(wordlist)
  File.open("grade#{wordlist.grade}.wordlist", 'w') do |file|
    wordlist.scrape_words.each do |word|
      file.puts word
    end
  end
end

def wordlist_to_json(wordlist)
  File.open("grade#{wordlist.grade}_wordlist.json", 'w') do |file|
    file.puts({
      grade: wordlist.grade,
      kind: "spelling",
      words: wordlist.scrape_words,
    }.to_json)
  end
end

options = BigIQKidsScraper::Options.parse(ARGV)

TEMP_DIR = "tmp"

(1..8).each do |grade|
  spelling_words = BigIQKidsScraper::SpellingWords.new grade

  Dir.mkdir(File.join(Dir.pwd, TEMP_DIR)) unless Dir.exists? TEMP_DIR

  Dir.chdir(TEMP_DIR) do
    case options.output
    when :plaintext
      wordlist_to_file(spelling_words)
    when :json
      wordlist_to_json(spelling_words)
    end
  end
end
