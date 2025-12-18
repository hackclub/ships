# Service class for interacting with Hack Club's Airtable proxy API.
# Uses https://api2.hackclub.com/v0.2/ with authKey authentication.
class HackclubAirtable
  BASE_URL = "https://api2.hackclub.com/v0.2".freeze
  BASE_ID = "Ships".freeze

  class << self
    # Fetches all records from a table.
    #
    # @param table_name [String] The table name.
    # @return [Array<Hash>] Array of record hashes.
    def records(table_name)
      url = build_url(table_name)
      response = connection.get(url) do |req|
        req.params["authKey"] = auth_key
      end

      unless response.success?
        Rails.logger.error "[HackclubAirtable] Failed to fetch records: #{response.status} - #{response.body}"
        return []
      end

      JSON.parse(response.body)
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.error "[HackclubAirtable] Error fetching records: #{e.message}"
      []
    end

    # Fetches a single record by ID.
    #
    # @param table_name [String] The table name.
    # @param record_id [String] The Airtable record ID.
    # @return [Hash, nil] Record hash or nil if not found.
    def find(table_name, record_id)
      url = "#{build_url(table_name)}/#{record_id}"
      response = connection.get(url) do |req|
        req.params["authKey"] = auth_key
      end

      unless response.success?
        Rails.logger.error "[HackclubAirtable] Failed to fetch record #{record_id}: #{response.status}"
        return nil
      end

      JSON.parse(response.body)
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.error "[HackclubAirtable] Error fetching record: #{e.message}"
      nil
    end

    private

    # Builds the API URL for a table.
    #
    # @param table_name [String] The table name.
    # @return [String] The full API URL.
    def build_url(table_name)
      encoded_table = ERB::Util.url_encode(table_name)
      "#{BASE_URL}/#{BASE_ID}/#{encoded_table}"
    end

    # Returns a configured Faraday connection.
    #
    # @return [Faraday::Connection] The connection instance.
    def connection
      @connection ||= Faraday.new do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end

    # Returns the authKey from credentials or environment.
    #
    # @return [String] The authKey for api2.hackclub.com.
    def auth_key
      Rails.application.credentials.dig(:airtable, :api_key) || ENV["HACKCLUB_API_AUTH_KEY"]
    end
  end
end
