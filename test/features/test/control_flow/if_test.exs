defmodule HologramFeatureTests.ControlFlow.IfTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.ControlFlow.IfPage

  # single-expression condition / single-expression if body / no else expression
  test "basic case", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Basic case")
    |> assert_text("#result", ":a")
  end

  test "multiple-expression condition", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Multiple-expression condition")
    |> assert_text("#result", ":a")
  end

  test "multiple-expression if body", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Multiple-expression if body")
    |> assert_text("#result", ":a")
  end

  test "unmet condition, no else body", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Unmet condition, no else body")
    |> assert_text("#result", "nil")
  end

  test "single-expression else body", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Single-expression else body")
    |> assert_text("#result", ":b")
  end

  test "multiple-expression else body", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Multiple-expression else body")
    |> assert_text("#result", ":c")
  end

  test "versioned x var handling", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Versioned x var handling")
    |> assert_text("#result", "11")
  end

  test "vars scoping in if body", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Vars scoping in if body")
    |> assert_text("#result", "{1, 2, 3, {11, 2, 3}}")
  end

  test "vars scoping in else body", %{page: page} do
    page
    |> visit(IfPage)
    |> click_button("Vars scoping in else body")
    |> assert_text("#result", "{1, 2, 3, {11, 2, 3}}")
  end

  test "error in condition", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(IfPage)
                          |> click_button("Error in condition")
                        end
  end

  test "error in if body", %{page: page} do
    assert_client_error page,
                        ArgumentError,
                        "my message",
                        fn ->
                          page
                          |> visit(IfPage)
                          |> click_button("Error in if body")
                        end
  end

  test "error in else body", %{page: page} do
    assert_client_error page,
                        ArgumentError,
                        "my message",
                        fn ->
                          page
                          |> visit(IfPage)
                          |> click_button("Error in else body")
                        end
  end
end
