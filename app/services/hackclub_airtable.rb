# Service class for interacting with the Airtable API directly.
# Uses https://api.airtable.com/v0/ with Bearer token authentication.
class HackclubAirtable
  BASE_URL = "https://api.airtable.com/v0".freeze
  OPEN_TIMEOUT = 60
  TIMEOUT = 300

  class << self
    # Fetches all records from a table, paginating through the full result set.
    #
    # @param table_name [String] The table name.
    # @return [Array<Hash>] Array of record hashes.
    def records(table_name)
      all_records = []
      offset = nil

      loop do
        url = build_url(table_name)
        response = connection.get(url) do |req|
          req.headers["Authorization"] = "Bearer #{auth_key}"
          req.params["offset"] = offset if offset
        end

        unless response.success?
          Rails.logger.error "[HackclubAirtable] Failed to fetch records: #{response.status} - #{response.body}"
          break
        end

        body = JSON.parse(response.body)
        all_records.concat(body["records"] || [])
        offset = body["offset"]

        break if offset.blank?
      end

      all_records
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.error "[HackclubAirtable] Error fetching records: #{e.message}"
      all_records
    end

    # Fetches a single record by ID.
    #
    # @param table_name [String] The table name.
    # @param record_id [String] The Airtable record ID.
    # @return [Hash, nil] Record hash or nil if not found.
    def find(table_name, record_id)
      url = "#{build_url(table_name)}/#{record_id}"
      response = connection.get(url) do |req|
        req.headers["Authorization"] = "Bearer #{auth_key}"
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
      "#{BASE_URL}/#{base_id}/#{encoded_table}"
    end

    # Returns a configured Faraday connection.
    #
    # @return [Faraday::Connection] The connection instance.
    def connection
      @connection ||= Faraday.new do |f|
        f.request :url_encoded
        f.options.open_timeout = OPEN_TIMEOUT
        f.options.timeout = TIMEOUT
        f.adapter Faraday.default_adapter
      end
    end

    # Returns the Airtable base ID from credentials.
    #
    # @return [String] The Airtable base ID.
    def base_id
      Rails.application.credentials.dig(:airtable, :base_id)
    end

    # Returns the Airtable personal access token from credentials or environment.
    #
    # @return [String] The auth token for api.airtable.com.
    def auth_key
      Rails.application.credentials.dig(:airtable, :api_key) || ENV["HACKCLUB_API_AUTH_KEY"]
    end
  end
end
