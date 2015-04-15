class ApiGetRequestList
  def self.call()
    new().get_data!
  end

  def initialize
    @path = "/1.0/resources/items/active_requests"
  end

  def get_data!
    params = nil
    headers = nil
    raw_results = ApiHandler.call("GET", @path, headers, params)

    requests = []

    raw_results["results"]["requests"].each do |res|
      if !res["barcode"].blank?
        criteria_type = "barcode"
        criteria = res["barcode"]
        item = GetItemFromBarcode.call(res["barcode"]) # Hack to make sure data is present for display.
      elsif !res["bib_number"].blank?
        criteria_type = "bib_number"
        criteria = res["bib_number"]
      else
        criteria_type = "ERROR" # Quick hack to cover when not available.
        criteria = "ERROR"
      end

      if res["request_type"] == "Doc Del"
        req_type = "checkout"
      else
        req_type = "scan"
      end

      if (res["rush"] == "No") || (res["rush"] == "Regular")
        rapid = false
      else
        rapid = true
      end

      if res["source"] == "Aleph"
        source = "aleph"
      else
        source = "illiad"
      end

      requests << { # Will add more info when rebuilding the batch page. Needs a migration.
        "trans" => res["transaction"],
        "criteria_type" => criteria_type,
        "criteria" => criteria,
        "requested" => Date.today.to_s, # Should be date requested, but that doesn't seem available.
        "rapid" => rapid,
        "source" => source,
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

    results = {"status" => raw_results["status"], "results" => requests}

    results
  end

end