require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "empty state is a quiet line without hint or action" do
    html = empty_state("Aucun pack.")
    assert_includes html, "empty-state"
    assert_not_includes html, "empty-state--block"
  end

  test "empty state with an action becomes a block" do
    html = empty_state("Aucun client.", hint: "Un client regroupe ses contacts.", action: link_to("+ Client", "/clients/new"))
    assert_includes html, "empty-state--block"
    assert_includes html, "Un client regroupe ses contacts."
    assert_includes html, %(href="/clients/new")
  end

  test "properties show blank values as empty" do
    html = properties("Type" => "Organisation", "N° de TVA" => nil)
    assert_includes html, "<dt>Type</dt><dd>Organisation</dd>"
    assert_includes html, %(<dd><span class="props__empty">Vide</span></dd>)
  end
end
