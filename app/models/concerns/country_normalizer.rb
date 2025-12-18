# Provides country code to name normalization to prevent duplicate entries.
module CountryNormalizer
  extend ActiveSupport::Concern

  # Maps ISO country codes to full country names.
  COUNTRY_CODE_MAP = {
    "US" => "United States",
    "USA" => "United States",
    "GB" => "United Kingdom",
    "UK" => "United Kingdom",
    "IN" => "India",
    "CA" => "Canada",
    "DE" => "Germany",
    "FR" => "France",
    "AU" => "Australia",
    "BR" => "Brazil",
    "JP" => "Japan",
    "CN" => "China",
    "RU" => "Russia",
    "MX" => "Mexico",
    "ES" => "Spain",
    "IT" => "Italy",
    "NL" => "Netherlands",
    "PL" => "Poland",
    "SE" => "Sweden",
    "NO" => "Norway",
    "DK" => "Denmark",
    "FI" => "Finland",
    "CH" => "Switzerland",
    "AT" => "Austria",
    "BE" => "Belgium",
    "PT" => "Portugal",
    "IE" => "Ireland",
    "NZ" => "New Zealand",
    "SG" => "Singapore",
    "HK" => "Hong Kong",
    "TW" => "Taiwan",
    "KR" => "South Korea",
    "TH" => "Thailand",
    "MY" => "Malaysia",
    "ID" => "Indonesia",
    "PH" => "Philippines",
    "VN" => "Vietnam",
    "PK" => "Pakistan",
    "BD" => "Bangladesh",
    "NP" => "Nepal",
    "LK" => "Sri Lanka",
    "EG" => "Egypt",
    "ZA" => "South Africa",
    "NG" => "Nigeria",
    "KE" => "Kenya",
    "GH" => "Ghana",
    "MA" => "Morocco",
    "AE" => "United Arab Emirates",
    "SA" => "Saudi Arabia",
    "IL" => "Israel",
    "TR" => "Turkey",
    "UA" => "Ukraine",
    "RO" => "Romania",
    "CZ" => "Czech Republic",
    "HU" => "Hungary",
    "GR" => "Greece",
    "AR" => "Argentina",
    "CL" => "Chile",
    "CO" => "Colombia",
    "PE" => "Peru",
    "VE" => "Venezuela"
  }.freeze

  class_methods do
    # Normalizes a country name/code to a consistent full name.
    #
    # @param country [String] The country name or code.
    # @return [String] The normalized country name.
    def normalize_country(country)
      return nil if country.blank?

      normalized = country.to_s.strip
      COUNTRY_CODE_MAP[normalized.upcase] || normalized
    end

    # Groups entries by normalized country and aggregates counts.
    #
    # @param entries [ActiveRecord::Relation] The entries to group.
    # @return [Hash] Country => count, sorted by count descending.
    def group_by_normalized_country(entries)
      entries
        .where.not(country: [ nil, "" ])
        .group(:country)
        .count
        .each_with_object(Hash.new(0)) do |(country, count), result|
          normalized = normalize_country(country)
          result[normalized] += count
        end
        .sort_by { |_, v| -v }
        .to_h
    end
  end
end
