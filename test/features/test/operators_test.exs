defmodule HologramFeatureTests.OperatorsTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.OperatorsPage

  @boolean_a true
  @boolean_b false

  @float_a 123.0

  @integer_a 123
  @integer_b 234
  @integer_c 345

  @list_a [1, 2, 3]
  @list_b [2, 3, 4]
  @list_float [1.0]
  @list_integer [1]

  @map_a %{a: @integer_a, b: @integer_b}
  @map_b %{a: @integer_a}

  @range_a @integer_a..@integer_c

  @string_a "aaa"
  @string_b "bbb"

  describe "overridable general operators" do
    test "unary +", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='unary+']")
      |> assert_text("#result", inspect(+@integer_a))
    end

    test "unary -", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='unary-']")
      |> assert_text("#result", inspect(-@integer_a))
    end

    test "+", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='+']")
      |> assert_text("#result", inspect(@integer_a + @integer_b))
    end

    test "-", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='-']")
      |> assert_text("#result", inspect(@integer_a - @integer_b))
    end

    test "*", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='*']")
      |> assert_text("#result", inspect(@integer_a * @integer_b))
    end

    test "/", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='/']")
      |> assert_text("#result", inspect(@integer_a / @integer_b))
    end

    test "++", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='++']")
      |> assert_text("#result", inspect(@list_a ++ @list_b))
    end

    test "--", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='--']")
      |> assert_text("#result", inspect(@list_a -- @list_b))
    end

    test "and", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='and']")
      |> assert_text("#result", inspect(wrap_term(@boolean_a) and wrap_term(@boolean_b)))
    end

    test "&&", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='&&']")
      |> assert_text("#result", inspect(wrap_term(@boolean_a) && wrap_term(@boolean_b)))
    end

    test "or", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='or']")
      |> assert_text("#result", inspect(wrap_term(@boolean_a) or wrap_term(@boolean_b)))
    end

    test "||", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='||']")
      |> assert_text("#result", inspect(wrap_term(@boolean_a) || wrap_term(@boolean_b)))
    end

    test "not", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='not']")
      |> assert_text("#result", inspect(not @boolean_a))
    end

    test "!", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='!']")
      |> assert_text("#result", inspect(!wrap_term(@boolean_a)))
    end

    test "in (list)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='in (list)']")
      |> assert_text("#result", inspect(@integer_a in @list_a))
    end

    test "in (map)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='in (map)']")
      |> assert_text("#result", inspect({:a, @integer_a} in @map_a))
    end

    test "in (range)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='in (range)']")
      |> assert_text("#result", inspect(@integer_b in @range_a))
    end

    test "not in (list)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='not in (list)']")
      |> assert_text("#result", inspect(@integer_a not in @list_a))
    end

    test "not in (map)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='not in (map)']")
      |> assert_text("#result", inspect({:a, @integer_a} not in @map_a))
    end

    test "not in (range)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='not in (range)']")
      |> assert_text("#result", inspect(@integer_b not in @range_a))
    end

    test "@", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='@']")
      |> assert_text("#result", inspect(@integer_c))
    end

    test "..", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='..']")
      |> assert_text("#result", inspect(@integer_a..@integer_b))
    end

    test "..//", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='..//']")
      |> assert_text("#result", inspect(@integer_a..@integer_b//@integer_c))
    end

    test "<>", %{page: page} do
      expected = inspect(@string_a <> @string_b)

      page
      |> visit(OperatorsPage)
      |> click("button[id='<>']")
      |> assert_text("#result", expected)
    end

    test "|>", %{page: page} do
      expected =
        @integer_a
        |> OperatorsPage.fun_1()
        |> OperatorsPage.fun_2()

      page
      |> visit(OperatorsPage)
      |> click("button[id='|>']")
      |> assert_text("#result", inspect(expected))
    end
  end

  describe "special form operators" do
    test "^", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='^']")
      |> assert_text("#result", inspect(@integer_b))
    end

    test ". (remote call)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='. (remote call)']")
      |> assert_text("#result", inspect([@integer_a, @integer_b, @integer_c]))
    end

    test ". (anonymous function call)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='. (anonymous function call)']")
      |> assert_text("#result", inspect(@integer_c * @integer_c))
    end

    test ". (map access)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='. (map access)']")
      |> assert_text("#result", inspect(@integer_b))
    end

    test "=", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='=']")
      |> assert_text("#result", inspect(@integer_a))
    end

    test "& (remote function)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='& (remote function)']")
      |> assert_text("#result", inspect([@integer_a, @integer_b, @integer_c]))
    end

    test "& (local function)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='& (local function)']")
      |> assert_text("#result", inspect(@integer_a * 4))
    end

    test "& (anonymous function)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='& (anonymous function)']")
      |> assert_text("#result", inspect(@integer_a * 5))
    end

    test "::", %{page: page} do
      expected = inspect(<<@float_a::float>>)

      page
      |> visit(OperatorsPage)
      |> click("button[id='::']")
      |> assert_text("#result", expected)
    end
  end

  describe "comparison operators" do
    test "==", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='==']")
      |> assert_text("#result", inspect(wrap_term(@integer_a) == wrap_term(@integer_a)))
    end

    test "===", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='===']")
      |> assert_text("#result", inspect(wrap_term(@integer_a) === wrap_term(@float_a)))
    end

    test "!=", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='!=']")
      |> assert_text("#result", inspect(@integer_a != @integer_b))
    end

    test "!==", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='!==']")
      |> assert_text("#result", inspect(@integer_a !== @float_a))
    end

    test "=== (map)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='=== (map)']")
      |> assert_text("#result", inspect(@map_b === @map_a))
    end

    test "== (map)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='== (map)']")
      |> assert_text("#result", inspect(@map_b == @map_a))
    end

    test "== (nested number)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='== (nested number)']")
      |> assert_text("#result", inspect(@list_integer == @list_float))
    end

    test "== (non-text binaries)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='== (non-text binaries)']")
      |> assert_text("#result", inspect({false, false, true, true}))
    end

    test "<", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='<']")
      |> assert_text("#result", inspect(@integer_a < @integer_b))
    end

    test ">", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='>']")
      |> assert_text("#result", inspect(@integer_b > @integer_a))
    end

    test "<=", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='<=']")
      |> assert_text("#result", inspect(@integer_a <= @integer_b))
    end

    test ">=", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='>=']")
      |> assert_text("#result", inspect(@integer_b >= @integer_a))
    end

    test "< (non-text binaries)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='< (non-text binaries)']")
      |> assert_text("#result", inspect({false, true, false, true}))
    end

    test "< (atoms above U+FFFF)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='< (atoms above U+FFFF)']")
      |> assert_text("#result", inspect({true, false, true, false}))
    end
  end

  describe "custom and overriden operators" do
    test "+++ (custom)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='+++ (custom)']")
      |> assert_text("#result", inspect(@integer_a * @integer_b - @integer_a))
    end

    test "+ (overriden)", %{page: page} do
      page
      |> visit(OperatorsPage)
      |> click("button[id='+ (overriden)']")
      |> assert_text("#result", inspect(@integer_a * @integer_b))
    end
  end
end
