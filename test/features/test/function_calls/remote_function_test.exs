defmodule HologramFeatureTests.FunctionCalls.RemoteFunctionTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.FunctionCalls.RemoteFunctionPage

  # IMPORTANT!
  # Keep consistent with Elixir/JavaScript consistency tests
  # in test/elixir/hologram/ex_js_consistency/interpreter_test.exs (call remote function section).

  # public function / Elixir function / no args / single clause / single-expression body
  test "basic case", %{page: page} do
    page
    |> visit(RemoteFunctionPage)
    |> click_button("Basic case")
    |> assert_text("#result", ":a")
  end

  test "private function", %{page: page} do
    assert_client_error page,
                        UndefinedFunctionError,
                        build_undefined_function_error_msg(
                          {HologramFeatureTests.ModuleFixture2, :fun_2, 0},
                          []
                        ),
                        fn ->
                          page
                          |> visit(RemoteFunctionPage)
                          |> click_button("Private function")
                        end
  end

  test "Erlang function", %{page: page} do
    page
    |> visit(RemoteFunctionPage)
    |> click_button("Erlang function")
    |> assert_text("#result", "1")
  end

  test "single arg", %{page: page} do
    page
    |> visit(RemoteFunctionPage)
    |> click_button("Single arg")
    |> assert_text("#result", ":a")
  end

  test "multiple args", %{page: page} do
    page
    |> visit(RemoteFunctionPage)
    |> click_button("Multiple args")
    |> assert_text("#result", "{:a, :b}")
  end

  test "multiple clauses", %{page: page} do
    page
    |> visit(RemoteFunctionPage)
    |> click_button("Multiple clauses")
    |> assert_text("#result", "{2, :a}")
  end

  test "multiple-expression body", %{page: page} do
    page
    |> visit(RemoteFunctionPage)
    |> click_button("Multiple-expression body")
    |> assert_text("#result", ":b")
  end

  test "vars scoping", %{page: page} do
    page
    |> visit(RemoteFunctionPage)
    |> click_button("Vars scoping")
    |> assert_text("#result", "{1, 2, {11, 5}}")
  end

  test "arity invalid, called with no args", %{page: page} do
    assert_client_error page,
                        UndefinedFunctionError,
                        build_undefined_function_error_msg(
                          {HologramFeatureTests.ModuleFixture2, :fun_4, 0},
                          []
                        ),
                        fn ->
                          page
                          |> visit(RemoteFunctionPage)
                          |> click_button("Arity invalid, called with no args")
                        end
  end

  test "arity invalid, called with single arg", %{page: page} do
    assert_client_error page,
                        UndefinedFunctionError,
                        build_undefined_function_error_msg(
                          {HologramFeatureTests.ModuleFixture2, :fun_4, 1},
                          []
                        ),
                        fn ->
                          page
                          |> visit(RemoteFunctionPage)
                          |> click_button("Arity invalid, called with single arg")
                        end
  end

  test "arity invalid, called with multiple args", %{page: page} do
    assert_client_error page,
                        UndefinedFunctionError,
                        build_undefined_function_error_msg(
                          {HologramFeatureTests.ModuleFixture2, :fun_3, 2},
                          []
                        ),
                        fn ->
                          page
                          |> visit(RemoteFunctionPage)
                          |> click_button("Arity invalid, called with multiple args")
                        end
  end

  test "no matching clause", %{page: page} do
    assert_client_error page,
                        FunctionClauseError,
                        build_function_clause_error_msg(
                          "HologramFeatureTests.ModuleFixture2.fun_5/2",
                          [4, 5],
                          [
                            "def fun_5(-1-, x)",
                            "def fun_5(-2-, x)",
                            "def fun_5(-3-, x)"
                          ]
                        ),
                        fn ->
                          page
                          |> visit(RemoteFunctionPage)
                          |> click_button("No matching clause")
                        end
  end

  test "Error in body", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(RemoteFunctionPage)
                          |> click_button("Error in body")
                        end
  end
end
