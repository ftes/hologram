defmodule HologramFeatureTests.TypesTest do
  use HologramFeatureTests.TestCase, async: true

  alias Hologram.Commons.SystemUtils
  alias HologramFeatureTests.TypesPage

  test "atom", %{page: page} do
    page
    |> visit(TypesPage)
    |> click("button[id='atom']")
    |> assert_text("#result", inspect(:abc))
  end

  describe "bitstring" do
    test "binary", %{page: page} do
      expected = inspect("abc")

      page
      |> visit(TypesPage)
      |> click("button[id='bitstring (binary)']")
      |> assert_text("#result", expected)
    end

    # The term starts on the client and comes back inside the action the server sends. The way
    # back is what is under test: the server writes the term into JavaScript, and a byte that is
    # not valid UTF-8 has no place in a string literal.
    test "binary, not valid UTF-8", %{page: page} do
      expected = inspect(<<240, 145, 163>>)

      page
      |> visit(TypesPage)
      |> click("button[id='bitstring (binary, not valid UTF-8)']")
      |> assert_text("#result", expected)
    end

    test "non-binary", %{page: page} do
      expected = inspect(<<1::1, 0::1, 1::1, 0::1>>)

      page
      |> visit(TypesPage)
      |> click("button[id='bitstring (non-binary)']")
      |> assert_text("#result", expected)
    end

    # Macro.escape splits this into a one-bit integer segment and a one-byte binary segment; the
    # binary segment is the part that has to travel as bytes.
    test "non-binary, not valid UTF-8", %{page: page} do
      expected = inspect(<<255, 1::1>>)

      page
      |> visit(TypesPage)
      |> click("button[id='bitstring (non-binary, not valid UTF-8)']")
      |> assert_text("#result", expected)
    end
  end

  test "float", %{page: page} do
    page
    |> visit(TypesPage)
    |> click("button[id='float']")
    |> assert_text("#result", inspect(1.23))
  end

  describe "function" do
    test "anonymous (client origin, non-capture)", %{page: page} do
      assert_js_error page,
                      "cannot serialize function: not a named function capture",
                      fn ->
                        page
                        |> visit(TypesPage)
                        |> click("button[id='anonymous function (client origin, non-capture)']")
                      end

      assert_text(page, "#result", inspect(8))
    end

    test "anonymous (server origin, non-capture)", %{page: page} do
      expected_msg =
        if SystemUtils.otp_version() >= 23 do
          "command failed: term contains a function that is not a named function capture"
        else
          "command failed: term contains a function that is not a remote function capture"
        end

      assert_js_error page, expected_msg, fn ->
        page
        |> visit(TypesPage)
        |> click("button[id='anonymous function (server origin, non-capture)']")
      end
    end

    test "anonymous (server origin, capture)", %{page: page} do
      expected_msg =
        if SystemUtils.otp_version() >= 23 do
          "command failed: term contains a function that is not a named function capture"
        else
          "command failed: term contains a function that is not a remote function capture"
        end

      assert_js_error page, expected_msg, fn ->
        page
        |> visit(TypesPage)
        |> click("button[id='anonymous function (server origin, capture)']")
      end
    end

    test "anonymous (client origin, capture)", %{page: page} do
      assert_js_error page,
                      "cannot serialize function: not a named function capture",
                      fn ->
                        page
                        |> visit(TypesPage)
                        |> click("button[id='anonymous function (client origin, capture)']")
                      end

      assert_text(page, "#result", inspect(8))
    end

    test "local capture (client origin)", %{page: page} do
      page
      |> visit(TypesPage)
      |> click("button[id='local function capture (client origin)']")
      |> assert_text("#result", "client = 8, server = 8, echo = 8")
    end

    test "local capture (server origin)", %{page: page} do
      if SystemUtils.otp_version() >= 23 do
        page
        |> visit(TypesPage)
        |> click("button[id='local function capture (server origin)']")
        |> assert_text("#result", inspect(8))
      else
        assert_js_error page,
                        "command failed: term contains a function that is not a remote function capture",
                        fn ->
                          page
                          |> visit(TypesPage)
                          |> click("button[id='local function capture (server origin)']")
                        end
      end
    end

    test "remote capture (client origin)", %{page: page} do
      page
      |> visit(TypesPage)
      |> click("button[id='remote function capture (client origin)']")
      |> assert_text("#result", "client = 8, server = 8, echo = 8")
    end

    test "remote capture (server origin)", %{page: page} do
      page
      |> visit(TypesPage)
      |> click("button[id='remote function capture (server origin)']")
      |> assert_text("#result", inspect(8))
    end

    test "Erlang capture (client origin)", %{page: page} do
      page
      |> visit(TypesPage)
      |> click("button[id='Erlang function capture (client origin)']")
      |> assert_text("#result", "client = [3, 2, 1], server = [3, 2, 1], echo = [3, 2, 1]")
    end

    test "Erlang capture (server origin)", %{page: page} do
      page
      |> visit(TypesPage)
      |> click("button[id='Erlang function capture (server origin)']")
      |> assert_text("#result", inspect([3, 2, 1]))
    end
  end

  test "integer", %{page: page} do
    page
    |> visit(TypesPage)
    |> click("button[id='integer']")
    |> assert_text("#result", inspect(123))
  end

  test "list", %{page: page} do
    page
    |> visit(TypesPage)
    |> click("button[id='list']")
    |> assert_text("#result", inspect([123, :abc]))
  end

  test "map", %{page: page} do
    expected = inspect(%{a: 123, b: "abc"})

    page
    |> visit(TypesPage)
    |> click("button[id='map']")
    |> assert_text("#result", expected)
  end

  describe "PID" do
    test "client origin", %{page: page} do
      assert_js_error page,
                      "cannot serialize PID: origin is client but destination is server",
                      fn ->
                        page
                        |> visit(TypesPage)
                        |> click("button[id='pid (client origin)']")
                      end
    end

    test "server origin", %{page: page} do
      expected =
        "0.11.222"
        |> pid()
        |> inspect()

      page
      |> visit(TypesPage)
      |> click("button[id='pid (server origin)']")
      |> assert_text("#result", expected)
    end
  end

  describe "reference" do
    test "client origin", %{page: page} do
      page
      |> visit(TypesPage)
      |> click("button[id='reference (client origin)']")
      |> assert_text("#result", "#Reference<0.1.2.3>")
    end

    test "server origin", %{page: page} do
      page
      |> visit(TypesPage)
      |> click("button[id='reference (server origin)']")
      |> assert_text("#result", "#Reference<1.2.3.4>")
    end
  end

  test "tuple", %{page: page} do
    page
    |> visit(TypesPage)
    |> click("button[id='tuple']")
    |> assert_text("#result", inspect({123, :abc}))
  end
end
