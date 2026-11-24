defmodule HologramFeatureTests.FunctionCalls.FunctionCaptureTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.FunctionCalls.FunctionCapturePage

  # IMPORTANT!
  # Keep consistent with Elixir/JavaScript consistency tests
  # in test/elixir/hologram/ex_js_consistency/interpreter_test.exs (call function capture section).

  test "single arg", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Single arg")
    |> assert_text("#result", ":a")
  end

  test "multiple args", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Multiple args")
    |> assert_text("#result", "{:a, :b}")
  end

  test "local private function capture", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Local private function capture")
    |> assert_text("#result", "{:a, :b}")
  end

  test "local public function capture", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Local public function capture")
    |> assert_text("#result", "{:a, :b}")
  end

  test "remote private Elixir function capture", %{page: page} do
    assert_client_error page,
                        UndefinedFunctionError,
                        "function HologramFeatureTests.ModuleFixture1.private_fun/2 is undefined or private",
                        fn ->
                          page
                          |> visit(FunctionCapturePage)
                          |> click_button("Remote private Elixir function capture")
                        end
  end

  test "remote public Elixir function capture", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Remote public Elixir function capture")
    |> assert_text("#result", "{:a, :b}")
  end

  test "remote Erlang function capture", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Remote Erlang function capture")
    |> assert_text("#result", "true")
  end

  test "partially applied local function capture", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Partially applied local function capture")
    |> assert_text("#result", "{:a, :b}")
  end

  test "partially applied remote Elixir function capture", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Partially applied remote Elixir function capture")
    |> assert_text("#result", "{:a, :b}")
  end

  test "partially applied remote Erlang function capture", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Partially applied remote Erlang function capture")
    |> assert_text("#result", "true")
  end

  test "vars scoping", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Vars scoping")
    |> assert_text("#result", "{1, 2, {3, 4, 2}}")
  end

  test "closure", %{page: page} do
    page
    |> visit(FunctionCapturePage)
    |> click_button("Closure")
    |> assert_text("#result", "{3, 4, {5, 1, 2}}")
  end

  test "arity invalid, called with no args", %{page: page} do
    assert_client_error page,
                        BadArityError,
                        ~r"^#Function<\d+\.\d+/2 in #{Regex.escape(inspect(FunctionCapturePage))}\.action/3> with arity 2 called with no arguments$",
                        fn ->
                          page
                          |> visit(FunctionCapturePage)
                          |> click_button("Arity invalid, called with no args")
                        end
  end

  test "arity invalid, called with single arg", %{page: page} do
    assert_client_error page,
                        BadArityError,
                        ~r"^#Function<\d+\.\d+/2 in #{Regex.escape(inspect(FunctionCapturePage))}\.action/3> with arity 2 called with 1 argument \(:a\)$",
                        fn ->
                          page
                          |> visit(FunctionCapturePage)
                          |> click_button("Arity invalid, called with single arg")
                        end
  end

  test "arity invalid, called with multiple args", %{page: page} do
    assert_client_error page,
                        BadArityError,
                        ~r"^#Function<\d+\.\d+/1 in #{Regex.escape(inspect(FunctionCapturePage))}\.action/3> with arity 1 called with 2 arguments \(:a, :b\)$",
                        fn ->
                          page
                          |> visit(FunctionCapturePage)
                          |> click_button("Arity invalid, called with multiple args")
                        end
  end

  test "Error in body", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(FunctionCapturePage)
                          |> click_button("Error in body")
                        end
  end
end
