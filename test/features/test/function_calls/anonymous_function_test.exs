defmodule HologramFeatureTests.FunctionCalls.AnonymousFunctionTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.FunctionCalls.AnonymousFunctionPage

  # IMPORTANT!
  # Keep consistent with Elixir/JavaScript consistency tests
  # in test/elixir/hologram/ex_js_consistency/interpreter_test.exs (call anonymous function section).

  # no args / single clause / single-expression body
  test "basic case", %{page: page} do
    page
    |> visit(AnonymousFunctionPage)
    |> click_button("Basic case")
    |> assert_text("#result", ":a")
  end

  test "single arg", %{page: page} do
    page
    |> visit(AnonymousFunctionPage)
    |> click_button("Single arg")
    |> assert_text("#result", "1")
  end

  test "multiple args", %{page: page} do
    page
    |> visit(AnonymousFunctionPage)
    |> click_button("Multiple args")
    |> assert_text("#result", "{1, 2}")
  end

  test "multiple clauses", %{page: page} do
    page
    |> visit(AnonymousFunctionPage)
    |> click_button("Multiple clauses")
    |> assert_text("#result", "{2, 3}")
  end

  test "multiple-expression body", %{page: page} do
    page
    |> visit(AnonymousFunctionPage)
    |> click_button("Multiple-expression body")
    |> assert_text("#result", ":b")
  end

  test "vars scoping", %{page: page} do
    page
    |> visit(AnonymousFunctionPage)
    |> click_button("Vars scoping")
    |> assert_text("#result", "{1, 2, 3, {15, 6, 3}}")
  end

  test "closure", %{page: page} do
    page
    |> visit(AnonymousFunctionPage)
    |> click_button("Closure")
    |> assert_text("#result", "{3, 4, {1, 2}}")
  end

  test "arity invalid, called with no args", %{page: page} do
    assert_client_error page,
                        BadArityError,
                        ~r"^#Function<\d+\.\d+/2 in #{Regex.escape(inspect(AnonymousFunctionPage))}\.action/3> with arity 2 called with no arguments$",
                        fn ->
                          page
                          |> visit(AnonymousFunctionPage)
                          |> click_button("Arity invalid, called with no args")
                        end
  end

  test "arity invalid, called with single arg", %{page: page} do
    assert_client_error page,
                        BadArityError,
                        ~r"^#Function<\d+\.\d+/2 in #{Regex.escape(inspect(AnonymousFunctionPage))}\.action/3> with arity 2 called with 1 argument \(:a\)$",
                        fn ->
                          page
                          |> visit(AnonymousFunctionPage)
                          |> click_button("Arity invalid, called with single arg")
                        end
  end

  test "arity invalid, called with multiple args", %{page: page} do
    assert_client_error page,
                        BadArityError,
                        ~r"^#Function<\d+\.\d+/1 in #{Regex.escape(inspect(AnonymousFunctionPage))}\.action/3> with arity 1 called with 2 arguments \(:a, :b\)$",
                        fn ->
                          page
                          |> visit(AnonymousFunctionPage)
                          |> click_button("Arity invalid, called with multiple args")
                        end
  end

  test "no matching clause", %{page: page} do
    assert_client_error page,
                        FunctionClauseError,
                        build_function_clause_error_msg(
                          "anonymous fn/2 in #{inspect(AnonymousFunctionPage)}.action/3",
                          [5, 6]
                        ),
                        fn ->
                          page
                          |> visit(AnonymousFunctionPage)
                          |> click_button("No matching clause")
                        end
  end

  test "Error in body", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(AnonymousFunctionPage)
                          |> click_button("Error in body")
                        end
  end
end
