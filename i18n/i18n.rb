require 'json'

module I18n
  FALLBACK_LOCALE_CODE = 'en-US'.freeze

  @translations = nil

  # Initializes translation dictionary with contents from /i18n/locales
  def self.initialize_translations
    return if @translations

    @translations = {}

    locales_path = File.join(Dir.pwd, 'public', 'locales', 'json')

    begin
      Dir.foreach(locales_path) do |filename|
        next unless filename.end_with?('.json')

        locale_name = filename.split('/').last.gsub('.json', '')

        File.open(File.join(locales_path, filename), 'r') do |f|
          @translations[locale_name] = JSON.load(f.read)
        end
      end
    rescue StandardError => e
      puts 'Error loading localization files.'
      puts e
    end
  end

  # Translate a static string
  # @param symbol [String] Identifier for static text
  # @param locale [String] Locale code
  #
  # @return [String]
  def self.translate(symbol, locale = 'en-US')
    locale_dict = @translations[locale]
    locale_dict = @translations[FALLBACK_LOCALE_CODE] unless locale_dict

    translated_value = locale_dict[symbol]
    return "Translation not found for #{symbol} in #{locale}" unless translated_value

    translated_value
  end

  # Checks if string is translatable
  # @param symbol [String] Identifier for static text
  # @param locale [String] Locale code
  #
  # @return [Boolean]
  def self.translation_available?(symbol, locale = 'en-US')
    !!(@translations[locale] || {})[symbol]
  end
end
