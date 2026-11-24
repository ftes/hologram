defmodule HologramFeatureTests.RegularExpressionsTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.RegularExpressionsPage

  test "client-sent regex", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='client-sent regex']")
    |> assert_text("#result", inspect(["gggh"]))
  end

  test "dynamic compilation", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='dynamic compilation']")
    |> assert_text("#result", inspect(["bb"]))
  end

  test "initial state regex", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='initial state regex']")
    |> assert_text("#result", inspect(["iij"]))
  end

  test "match operator", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='match operator']")
    |> assert_text("#result", inspect(true))
  end

  test "named captures", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='named captures']")
    |> assert_text("#result", inspect(%{"number" => "42"}))
  end

  test "regex match?", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='regex match?']")
    |> assert_text("#result", inspect(false))
  end

  test "regex replace", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='regex replace']")
    |> assert_text("#result", inspect("aXc"))
  end

  test "regex run", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='regex run']")
    |> assert_text("#result", inspect(["abb", "bb"]))
  end

  test "regex scan", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='regex scan']")
    |> assert_text("#result", inspect([["1"], ["3"]]))
  end

  test "regex split", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='regex split']")
    |> assert_text("#result", inspect(["1", "2", "3"]))
  end

  test "server-sent regex", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='server-sent regex']")
    |> assert_text("#result", inspect(["eef"]))
  end

  test "unicode property escape", %{page: page} do
    page
    |> visit(RegularExpressionsPage)
    |> click("button[id='unicode property escape']")
    |> assert_text("#result", inspect(["zażółć"]))
  end
end
