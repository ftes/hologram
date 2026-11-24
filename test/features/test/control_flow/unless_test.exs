defmodule HologramFeatureTests.ControlFlow.UnlessTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.ControlFlow.UnlessPage

  # single-expression condition / single-expression unless body / no else expression
  test "basic case", %{page: page} do
    page
    |> visit(UnlessPage)
    |> click_button("Basic case")
    |> assert_text("#result", ":a")
  end

  test "multiple-expression condition", %{page: page} do
    page
    |> visit(UnlessPage)
    |> click_button("Multiple-expression condition")
    |> assert_text("#result", ":a")
  end

  test "multiple-expression unless body", %{page: page} do
    page
    |> visit(UnlessPage)
    |> click_button("Multiple-expression unless body")
    |> assert_text("#result", ":a")
  end

  test "unmet condition, no else body", %{page: page} do
    page
    |> visit(UnlessPage)
    |> click_button("Unmet condition, no else body")
    |> assert_text("#result", "nil")
  end

  test "single-expression else body", %{page: page} do
    page
    |> visit(UnlessPage)
    |> click_button("Single-expression else body")
    |> assert_text("#result", ":b")
  end

  test "multiple-expression else body", %{page: page} do
    page
    |> visit(UnlessPage)
    |> click_button("Multiple-expression else body")
    |> assert_text("#result", ":c")
  end

  test "vars scoping in unless body", %{page: page} do
    page
    |> visit(UnlessPage)
    |> click_button("Vars scoping in unless body")
    |> assert_text("#result", "{1, 2, 3, {11, 2, 3}}")
  end

  test "vars scoping in else body", %{page: page} do
    page
    |> visit(UnlessPage)
    |> click_button("Vars scoping in else body")
    |> assert_text("#result", "{1, 2, 3, {11, 2, 3}}")
  end

  test "error in condition", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(UnlessPage)
                          |> click_button("Error in condition")
                        end
  end

  test "error in unless body", %{page: page} do
    assert_client_error page,
                        ArgumentError,
                        "my message",
                        fn ->
                          page
                          |> visit(UnlessPage)
                          |> click_button("Error in unless body")
                        end
  end

  test "error in else body", %{page: page} do
    assert_client_error page,
                        ArgumentError,
                        "my message",
                        fn ->
                          page
                          |> visit(UnlessPage)
                          |> click_button("Error in else body")
                        end
  end
end
