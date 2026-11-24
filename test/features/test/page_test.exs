defmodule HologramFeatureTests.PagesTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Pages.TemplateFilePage
  alias HologramFeatureTests.Pages.TemplateFunctionPage

  test "template defined in function", %{page: page} do
    page
    |> visit(TemplateFunctionPage)
    |> assert_text("Template defined in function")
  end

  test "template defined in file", %{page: page} do
    page
    |> visit(TemplateFilePage)
    |> assert_text("Template defined in file")
  end
end
