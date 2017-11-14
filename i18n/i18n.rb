require 'json'

module I18n
  @translations = nil

  # Initializes translation dictionary with contents from /i18n/locales
  def self.initialize_translations
    return if @translations

    @translations = {}

    locales_path = File.join(Dir.pwd, 'i18n', 'locales')

    begin
      Dir.foreach(locales_path) do |filename|
        next if !filename.end_with?('.json')

        locale_name = filename.split('/').last.gsub('.json', '')

        File.open(File.join(locales_path, filename), 'r') do |f|
          @translations[locale_name] = JSON.load(f.read)
        end
      end
    rescue Exception => e
      puts 'Error loading localization files.'
      puts e
    end
  end

  # Translate a static string
  # @param symbol string Identifier for static text
  # @param locale string Locale code
  #
  # @returns string
  def self.translate(symbol, locale = 'en-US')
    locale_dict = @translations[locale]
    return "Localization file for #{locale} is not available" unless locale_dict

    translated_value = locale_dict[symbol]
    return "Translation not found for #{symbol} in #{locale}" unless translated_value

    translated_value
  end

  # Checks if string is translatable
  # @param symbol string Identifier for static text
  # @param locale string Locale code
  #
  # @returns boolean
  def self.translation_avaliable(symbol, locale = 'en-US')
    return !!(@translations[locale] || {})[symbol]
  end
end
