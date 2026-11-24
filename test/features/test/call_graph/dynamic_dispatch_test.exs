defmodule HologramFeatureTests.DynamicDispatchTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.CallGraph.DynamicDispatchPage

  test "Date.new/3", %{page: page} do
    expected = "{:ok, %{__struct__: Date, calendar: Calendar.ISO, day: 15, month: 6, year: 2024}}"

    page
    |> visit(DynamicDispatchPage)
    |> click_button("Date.new")
    |> assert_text("#result", expected)
  end
end
