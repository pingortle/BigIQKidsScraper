require 'rubygems'
require 'nokogiri'   
require 'open-uri'
require 'json'
require 'ostruct'
require 'optparse'

module BigIQKidsScraper
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
end

def wordlist_to_file(wordlist, filename)
  File.open(filename, 'w') do |file|
    wordlist.each do |word|
      file.puts word
    end
  end
end

def wordlist_to_json(wordlist, filename, grade)
  File.open(filename, 'w') do |file|
    file.puts({
      grade: grade,
      kind: "spelling",
      words: wordlist,
    }.to_json)
  end
end

options = BigIQKidsScraper::Options.parse(ARGV)

TEMP_DIR = "tmp"

urls = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth']
.map {|ordinal| "http://www.bigiqkids.com/SpellingVocabulary/Lessons/wordlistSpelling#{ordinal}Grade.shtml"}

(1..8).each do |grade|
	page = Nokogiri::HTML(open(urls[grade - 1]))

  wordlist = page.css('table tr td a')
    .select {|x| x.text.split(' ').count == 1}
    .map {|x| x.text.downcase}

  Dir.mkdir(File.join(Dir.pwd, TEMP_DIR)) unless Dir.exists? TEMP_DIR

  Dir.chdir(TEMP_DIR) do
    case options.output
    when :plaintext
      wordlist_to_file(wordlist, "grade#{grade}.wordlist")
    when :json
      wordlist_to_json(wordlist, "grade#{grade}_wordlist.json", grade)
    end
  end
end
