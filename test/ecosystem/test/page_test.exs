defmodule HologramEcosystemTests.PageTest do
  use HologramEcosystemTests.TestCase, async: false

  alias HologramEcosystemTests.PlainPage

  test "a page request is served", %{page: page} do
    page
    |> visit(PlainPage)
    |> assert_text("#text", "Served with the ecosystem libraries")
  end
end
