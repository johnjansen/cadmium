module Cadmium
  # A syntactical analyzer that helps determine the readibility
  # of a block of text.
  class Readability
    getter text : String
    getter paragraphs : Array(String)
    getter sentences : Array(String)
    getter words : Array(String)
    getter frequencies : Hash(String, Int32)

    # The constructor accepts the text to be analysed, and returns a report
    # object which gives access to the
    def initialize(text)
      @text = text.dup
      @paragraphs = Cadmium::Util::Paragraph.paragraphs(@text)
      @sentences = Cadmium::Util::Sentence.sentences(@text)
      @words = [] of String
      @frequencies = {} of String => Int32
      @frequencies["default"] = 0
      @syllables = 0
      @complex_words = 0
      count_words
    end

    # The number of paragraphs in the sample. A paragraph is defined as a
    # newline followed by one or more empty or whitespace-only lines.
    def num_paragraphs
      paragraphs.size
    end

    # The number of sentences in the sample. The meaning of a "sentence" is
    # defined by Cadmium::Util::Sentence.
    def num_sentences
      sentences.size
    end

    # The number of characters in the sample.
    def num_chars
      text.size
    end

    # The total number of words used in the sample. Numbers as digits are not
    # counted.
    def num_words
      words.size
    end

    # The total number of syllables in the text sample. Just for completeness.
    def num_syllables
      @syllables
    end

    # The number of different unique words used in the text sample.
    def num_unique_words
      @frequencies.keys.size
    end

    # An array containing each unique word used in the text sample.
    def unique_words
      @frequencies.keys
    end

    # The number of occurences of the word +word+ in the text sample.
    def occurrences(word)
      @frequencies[word]
    end

    # The average number of words per sentence.
    def words_per_sentence
      words.size.to_f / sentences.size.to_f
    end

    # The average number of syllables per word. The syllable count is
    # performed by Cadmium::Util::Syllable, and so may not be completely
    # accurate, especially if the Carnegie-Mellon Pronouncing Dictionary
    # is not installed.
    def syllables_per_word
      @syllables.to_f / words.size.to_f
    end

    # Flesch-Kincaid level of the text sample. This measure scores text based
    # on the American school grade system; a score of 7.0 would indicate that
    # the text is readable by a seventh grader. A score of 7.0 to 8.0 is
    # regarded as optimal for ordinary text.
    def kincaid
      (11.8 * syllables_per_word) + (0.39 * words_per_sentence) - 15.59
    end

    # Flesch reading ease of the text sample. A higher score indicates text
    # that is easier to read. The score is on a 100-point scale, and a score
    # of 60-70 is regarded as optimal for ordinary text.
    def flesch
      206.835 - (1.015 * words_per_sentence) - (84.6 * syllables_per_word)
    end

    # The Gunning Fog Index of the text sample. The index indicates the number
    # of years of formal education that a reader of average intelligence would
    # need to comprehend the text. A higher score indicates harder text; a
    # value of around 12 is indicated as ideal for ordinary text.
    def fog
      (words_per_sentence + percent_fog_complex_words) * 0.4
    end

    # The percentage of words that are defined as "complex" for the purpose of
    # the Fog Index. This is non-hyphenated words of three or more syllabes.
    def percent_fog_complex_words
      (@complex_words.to_f / words.size.to_f) * 100
    end

    # Return a nicely formatted report on the sample, showing most the useful
    # statistics about the text sample.
    def report
      sprintf "Number of paragraphs           %d \n" +
              "Number of sentences            %d \n" +
              "Number of words                %d \n" +
              "Number of characters           %d \n\n" +
              "Average words per sentence     %.2f \n" +
              "Average syllables per word     %.2f \n\n" +
              "Flesch score                   %2.2f \n" +
              "Flesch-Kincaid grade level     %2.2f \n" +
              "Fog Index                      %2.2f \n",
        num_paragraphs, num_sentences, num_words, num_chars,
        words_per_sentence, syllables_per_word,
        flesch, kincaid, fog
    end

    private def count_words
      @text.scan(/\b([a-z][a-z\-']*)\b/i).each do |match|
        word = match[0]
        @words << word

        # up frequency counts
        @frequencies.has_key?(word) ? (@frequencies[word] += 1) : (@frequencies[word] = 1)

        # syllable counts
        syllables = Cadmium::Util::Syllable.syllables(word)
        @syllables += syllables
        if syllables > 2 && !word.includes?('-')
          @complex_words += 1 # for Fog Index
        end
      end
    end
  end
end
