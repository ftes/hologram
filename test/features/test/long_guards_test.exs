defmodule HologramFeatureTests.LongGuardsTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.LongGuardsPage

  # The number of values in each of the page's lists - keep in step with @value_count there.
  @value_count 600

  test "atom list", %{page: page} do
    page
    |> visit(LongGuardsPage)
    |> click_button("Atom list")
    |> assert_text("#result", ":atom_match")
  end

  test "binary list", %{page: page} do
    page
    |> visit(LongGuardsPage)
    |> click_button("Binary list")
    |> assert_text("#result", ":binary_match")
  end

  test "case clause", %{page: page} do
    page
    |> visit(LongGuardsPage)
    |> click_button("Case clause")
    |> assert_text("#result", ":case_match")
  end

  test "fall through to the next clause", %{page: page} do
    page
    |> visit(LongGuardsPage)
    |> click_button("Fall through")
    |> assert_text("#result", ":binary_no_match")
  end

  test "integer list", %{page: page} do
    page
    |> visit(LongGuardsPage)
    |> click_button("Integer list")
    |> assert_text("#result", ":integer_match")
  end

  test "loose chain", %{page: page} do
    page
    |> visit(LongGuardsPage)
    |> click_button("Loose chain")
    |> assert_text("#result", ":loose_match")
  end

  test "mixed list", %{page: page} do
    page
    |> visit(LongGuardsPage)
    |> click_button("Mixed list")
    |> assert_text("#result", ":mixed_match")
  end

  test "no matching clause", %{page: page} do
    attempted_guard = Enum.map_join(1..@value_count, " or ", &~s(-x === "Zone/#{&1}"-))

    assert_client_error page,
                        FunctionClauseError,
                        build_function_clause_error_msg(
                          "HologramFeatureTests.LongGuardsPage.only_binaries/1",
                          [123],
                          ["def only_binaries(x) when #{attempted_guard}"]
                        ),
                        fn ->
                          page
                          |> visit(LongGuardsPage)
                          |> click_button("No matching clause")
                        end
  end
end
