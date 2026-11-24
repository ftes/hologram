defmodule App1.NpmImportTest do
  use App1.TestCase, async: true

  test "runs an action using an npm package", %{page: page} do
    page
    |> visit(App1.NpmImportPage)
    |> click_button("Add decimals")
    |> assert_text("#result", "123")
  end
end
