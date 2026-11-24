defmodule HologramFeatureTests.ControlFlow.RaisingTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.ControlFlow.RaisingPage

  test "raise with module", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(RaisingPage)
                          |> click_button("Raise Module")
                        end
  end

  test "raise with string", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my string",
                        fn ->
                          page
                          |> visit(RaisingPage)
                          |> click_button("Raise String")
                        end
  end

  test "throw", %{page: page} do
    assert_js_error page,
                    ~s/(throw) "my value"/,
                    fn ->
                      page
                      |> visit(RaisingPage)
                      |> click_button("Throw")
                    end
  end

  test "exit", %{page: page} do
    assert_js_error page,
                    ~s/(exit) "my reason"/,
                    fn ->
                      page
                      |> visit(RaisingPage)
                      |> click_button("Exit")
                    end
  end
end
