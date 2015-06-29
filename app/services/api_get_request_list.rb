class ApiGetRequestList
  attr_reader :user_id

  def self.call(user_id)
    new(user_id).get_data!
  end

  def initialize(user_id)
    @user_id = user_id
  end

  def get_data!
    params = nil
    headers = nil

    requests = []

    response = ApiHandler.get(:active_requests, params)
    if response.success?
      requests = parse_requests(response.body[:requests])
    end

    ApiResponse.new(status_code: response.status_code, body: requests)
  end

  def parse_requests(requests_data)
    requests = []
    requests_data.each do |res|
      if !res["barcode"].blank?
        criteria_type = "barcode"
        criteria = res["barcode"]
        GetItemFromBarcode.call(user_id, res["barcode"]) # Hack to make sure data is present for display.
      elsif !res["bib_number"].blank?
        criteria_type = "bib_number"
        criteria = res["bib_number"]
      elsif !res["isbn_issn"].blank?
        criteria_type = "isbn_issn"
        criteria = res["isbn_issn"]
      elsif !res["title"].blank?
        criteria_type = "title"
        criteria = res["title"]
      else
        criteria_type = "ERROR" # Quick hack to cover when not available.
        criteria = "ERROR"
      end

      del_type = res["delivery_type"].downcase
      source = res["source"].downcase

      req_type = res["request_type"].downcase.gsub(" ", "_")

      if (res["rush"] == "No") || (res["rush"] == "Regular")
        rapid = false
      else
        rapid = true
      end

      trans = res["transaction"].gsub("doc-del", "aleph").gsub("-", "_")

      requests << { # Will add more info when rebuilding the batch page. Needs a migration.
        "trans" => trans,
        "criteria_type" => criteria_type,
        "criteria" => criteria,
        "requested" => Date.today.to_s, # Should be date requested, but that doesn"t seem available.
        "rapid" => rapid,
        "source" => source,
        "del_type" => del_type,
        "req_type" => req_type,
        "title" => res["title"],
        "article_title" => res["article_title"],
        "author" => res["author"],
        "description" => res["description"],
        "barcode" => res["barcode"],
        "isbn_issn" => res["isbn_issn"],
        "bib_number" => res["bib_number"]
      }
    end

    requests
  end

end
