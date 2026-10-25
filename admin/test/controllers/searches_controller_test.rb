require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "requires authentication" do
    sign_out
    get search_path(q: "dici", format: :json)
    assert_response :redirect
  end

  test "lists pages, actions and recent clients without a query" do
    get search_path, as: :json
    groups = response.parsed_body["results"].pluck("group").uniq
    assert_equal [ "Pages", "Actions", "Clients récents" ], groups
  end

  test "finds records and pages by name, ignoring accents and case" do
    get search_path(q: "d'ici"), as: :json
    assert_includes response.parsed_body["results"], { "group" => "Clients", "label" => "D'ici", "url" => client_path(clients(:dici)), "hint" => "Actif" }

    get search_path(q: "PILOTAGE"), as: :json
    assert_equal [ { "group" => "Pages", "label" => "Pilotage", "url" => tax_projection_path, "hint" => nil } ], response.parsed_body["results"]
  end

  test "hides create actions from read-only users" do
    sign_in_as users(:accountant)
    get search_path(q: "nouveau"), as: :json
    assert_empty response.parsed_body["results"].select { |result| result["group"] == "Actions" }
  end
end
