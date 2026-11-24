defmodule HologramFeatureTests.FunctionCalls.LocalFunctionTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.FunctionCalls.LocalFunctionPage

  # IMPORTANT!
  # Keep consistent with Elixir/JavaScript consistency tests
  # in test/elixir/hologram/ex_js_consistency/interpreter_test.exs (call local function section).

  # public function / no args / single clause / single-expression body
  test "basic case", %{page: page} do
    page
    |> visit(LocalFunctionPage)
    |> click_button("Basic case")
    |> assert_text("#result", ":a")
  end

  test "private function", %{page: page} do
    page
    |> visit(LocalFunctionPage)
    |> click_button("Private function")
    |> assert_text("#result", ":a")
  end

  test "single arg", %{page: page} do
    page
    |> visit(LocalFunctionPage)
    |> click_button("Single arg")
    |> assert_text("#result", ":a")
  end

  test "multiple args", %{page: page} do
    page
    |> visit(LocalFunctionPage)
    |> click_button("Multiple args")
    |> assert_text("#result", "{:a, :b}")
  end

  test "multiple clauses", %{page: page} do
    page
    |> visit(LocalFunctionPage)
    |> click_button("Multiple clauses")
    |> assert_text("#result", "{2, :a}")
  end

  test "multiple-expression body", %{page: page} do
    page
    |> visit(LocalFunctionPage)
    |> click_button("Multiple-expression body")
    |> assert_text("#result", ":b")
  end

  test "vars scoping", %{page: page} do
    page
    |> visit(LocalFunctionPage)
    |> click_button("Vars scoping")
    |> assert_text("#result", "{1, 2, {11, 5}}")
  end

  test "no matching clause", %{page: page} do
    assert_client_error page,
                        FunctionClauseError,
                        build_function_clause_error_msg(
                          "HologramFeatureTests.FunctionCalls.LocalFunctionPage.local_fun_4/2",
                          [4, 5],
                          [
                            "def local_fun_4(-1-, x)",
                            "def local_fun_4(-2-, x)",
                            "def local_fun_4(-3-, x)"
                          ]
                        ),
                        fn ->
                          page
                          |> visit(LocalFunctionPage)
                          |> click_button("No matching clause")
                        end
  end

  test "Error in body", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(LocalFunctionPage)
                          |> click_button("Error in body")
                        end
  end
end
