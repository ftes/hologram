defmodule HologramFeatureTests.TemplateSyntaxTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.TemplateSyntax.AttributeSpreadPage
  alias HologramFeatureTests.TemplateSyntax.ComponentPage
  alias HologramFeatureTests.TemplateSyntax.DynamicComponentBroadcastReceiverPage
  alias HologramFeatureTests.TemplateSyntax.DynamicComponentBroadcastSenderPage
  alias HologramFeatureTests.TemplateSyntax.DynamicComponentPage
  alias HologramFeatureTests.TemplateSyntax.DynamicComponentSwapPage
  alias HologramFeatureTests.TemplateSyntax.DynamicElementPage
  alias HologramFeatureTests.TemplateSyntax.ForBlockPage
  alias HologramFeatureTests.TemplateSyntax.IfBlockPage
  alias HologramFeatureTests.TemplateSyntax.InlineStylesheetPage
  alias HologramFeatureTests.TemplateSyntax.InterpolationPage
  alias HologramFeatureTests.TemplateSyntax.PropSpreadPage
  alias HologramFeatureTests.TemplateSyntax.PublicCommentPage
  alias HologramFeatureTests.TemplateSyntax.RawBlockPage
  alias HologramFeatureTests.TemplateSyntax.ScriptInterpolationPage
  alias HologramFeatureTests.TemplateSyntax.StyleInterpolationPage
  alias HologramFeatureTests.TemplateSyntax.TextAndElementPage

  @broadcast_channel :template_syntax_dynamic_component

  describe "nodes" do
    test "text and element", %{page: page} do
      page
      |> visit(TextAndElementPage)
      |> assert_has("div.parent_elem span.child_elem", text: "my text")
    end

    test "component", %{page: page} do
      page
      |> visit(ComponentPage)
      |> assert_has("div#my_component", text: "abc")
    end
  end

  describe "for block" do
    test "having items", %{page: page} do
      page
      |> visit(ForBlockPage)
      |> assert_count("#block_1 .item", 3)
      |> assert_has("#block_1 #item_1.item", text: "text_1")
      |> assert_has("#block_1 #item_2.item", text: "text_2")
      |> assert_has("#block_1 #item_3.item", text: "text_3")
    end

    test "not having items", %{page: page} do
      page
      |> visit(ForBlockPage)
      |> assert_has("#block_2", text: "abcxyz")
    end
  end

  describe "if block" do
    test "with truthy condition", %{page: page} do
      page
      |> visit(IfBlockPage)
      |> assert_has("#block_1", text: "abc")
    end

    test "with falsy condition, having else subblock", %{page: page} do
      page
      |> visit(IfBlockPage)
      |> assert_has("#block_2", text: "acd")
    end

    test "with falsy condition, not having else subblock", %{page: page} do
      page
      |> visit(IfBlockPage)
      |> assert_has("#block_3", text: "ac")
    end
  end

  test "raw block", %{page: page} do
    page
    |> visit(RawBlockPage)
    |> assert_has("body", text: "{%if false}abc{@var}xyz{/if}")
  end

  describe "interpolation" do
    test "in text", %{page: page} do
      page
      |> visit(InterpolationPage)
      |> assert_has("span.node_1", text: "a2c")
    end

    test "in attribute value", %{page: page} do
      page
      |> visit(InterpolationPage)
      |> assert_has("span.node_2", text: "xyz")
    end

    test "uses String.Chars protocol", %{page: page} do
      page
      |> visit(InterpolationPage)
      |> assert_has("#string_chars_protocol", text: "1.2.3")
    end

    # The value is the page's, repeated here rather than read from it. Each run of the page's
    # script appends the value as read through double quotes, single quotes and backticks, so one
    # entry of three equal strings means the value arrived intact through each kind of literal and
    # the script ran once - the client rendered the same text the server wrote, and hydration
    # adopted the element. The closing tag inside the value did not end the element, or the
    # marker it carries would be set.
    test "in script element", %{page: page} do
      value = ~s(</script><script>window.__xss = true</script> & "a" 'b' `c` ${d} e\\f\ng)

      page
      |> visit(ScriptInterpolationPage)
      |> assert_script_result("return window.__scriptInterpolation;", [[value, value, value]])
      |> assert_script_result("return window.__xss;", nil)
    end

    # The value read back out of the stylesheet is compared against the same value carried through
    # a script interpolation, which #1101 established arrives exact - so the expected value is not
    # written out a second time here. Chrome serializes a computed "content" with wrapping quotes
    # and backslash escapes, which the decode below undoes. The visibility assertion is the other
    # half: the closing tag inside the value did not end the element, or the rule it carries would
    # have hidden the div.
    test "in style element", %{page: page} do
      decode = """
      const css = window.__styleInterpolation.content;
      const decoded = css.slice(1, -1).replace(/\\\\(.)/g, "$1");
      return decoded === window.__styleInterpolationExpected;
      """

      page
      |> visit(StyleInterpolationPage)
      |> assert_script_result(decode, true)
      |> assert_script_result("return window.__styleInterpolation.visibility;", "visible")
      |> assert_script_result(
        "return window.__styleInterpolation.text === document.getElementById('style_interpolation_sheet').textContent;",
        true
      )
    end
  end

  # The stylesheet is read at parse time, before the runtime boots, so these are the server's own
  # bytes rather than the client's repair of them. The last assertion compares that text with what
  # the element holds after hydration: equal means the client rendered the same stylesheet and the
  # boot patch adopted it instead of rewriting it.
  test "inline stylesheet", %{page: page} do
    page
    |> visit(InlineStylesheetPage)
    |> assert_script_result("return window.__inlineStylesheet.color;", "rgb(1, 2, 3)")
    |> assert_script_result("return window.__inlineStylesheet.content;", ~s("a & b"))
    |> assert_script_result(
      "return window.__inlineStylesheet.text === document.getElementById('inline_stylesheet_sheet').textContent;",
      true
    )
  end

  test "public comment", %{page: page} do
    page
    |> visit(PublicCommentPage)
    |> assert_public_comment("my comment")
  end

  describe "attribute spread" do
    test "map value", %{page: page} do
      page
      |> visit(AttributeSpreadPage)
      |> assert_has("#scenario_1[title='value_1']")
    end

    test "keyword shorthand value", %{page: page} do
      page
      |> visit(AttributeSpreadPage)
      |> assert_has("#scenario_2[title='value_2']")
    end

    test "state value", %{page: page} do
      page
      |> visit(AttributeSpreadPage)
      |> assert_has("#scenario_3[title='value_3']")
    end

    test "nested value composes a dash-joined name", %{page: page} do
      page
      |> visit(AttributeSpreadPage)
      |> assert_has("#scenario_4[data-user-id='value_4']")
    end

    test "entry with nil value is not rendered", %{page: page} do
      page
      |> visit(AttributeSpreadPage)
      |> assert_has("#scenario_5[class='value_5']:not([title])")
    end

    test "literal attribute before the spread is overridden", %{page: page} do
      page
      |> visit(AttributeSpreadPage)
      |> assert_has("#scenario_6[title='value_6']")
    end

    test "literal attribute after the spread wins", %{page: page} do
      page
      |> visit(AttributeSpreadPage)
      |> assert_has("#scenario_7[title='value_7']")
    end

    test "later spread wins over an earlier one", %{page: page} do
      page
      |> visit(AttributeSpreadPage)
      |> assert_has("#scenario_8[title='value_8']")
    end
  end

  describe "prop spread" do
    test "map value", %{page: page} do
      page
      |> visit(PropSpreadPage)
      |> assert_has("#scenario_1", text: "prop_1 = value_1")
    end

    test "keyword shorthand value", %{page: page} do
      page
      |> visit(PropSpreadPage)
      |> assert_has("#scenario_2", text: "prop_1 = value_2")
    end

    test "state value", %{page: page} do
      page
      |> visit(PropSpreadPage)
      |> assert_has("#scenario_3", text: "prop_1 = value_3")
    end

    test "undeclared keys are filtered out", %{page: page} do
      page
      |> visit(PropSpreadPage)
      |> assert_has("#scenario_4", text: "prop_1 = value_4")
    end

    test "named prop before the spread is overridden", %{page: page} do
      page
      |> visit(PropSpreadPage)
      |> assert_has("#scenario_5", text: "prop_1 = value_5")
    end

    test "named prop after the spread wins", %{page: page} do
      page
      |> visit(PropSpreadPage)
      |> assert_has("#scenario_6", text: "prop_1 = value_6")
    end

    test "cid supplied through a spread initializes a stateful component", %{page: page} do
      page
      |> visit(PropSpreadPage)
      |> assert_has("#scenario_7", text: "my_state_value = value_7")
    end

    test "forwarding wrapper spreads its map prop onto an inner element", %{page: page} do
      page
      |> visit(PropSpreadPage)
      |> assert_has("#scenario_8[title='value_8']", text: "forwarded")
    end
  end

  describe "dynamic component" do
    test "named props", %{page: page} do
      page
      |> visit(DynamicComponentPage)
      |> assert_has("#scenario_1", text: "prop_1 = value_1")
    end

    test "spread props", %{page: page} do
      page
      |> visit(DynamicComponentPage)
      |> assert_has("#scenario_2", text: "prop_1 = value_2")
    end

    test "slot content", %{page: page} do
      page
      |> visit(DynamicComponentPage)
      |> assert_has("#scenario_3", text: "slot content = value_3")
    end

    test "module delivered from a command", %{page: page} do
      page
      |> visit(DynamicComponentPage)
      |> click("#scenario_4_button")
      |> assert_has("#scenario_4", text: "loaded from command")
    end

    # The component is referenced only in the sender page's command/3, so the receiver
    # page can render it only if broadcast-referenced components reach the runtime bundle.
    test "module delivered from a broadcast to another page", %{browser: browser, page: session_1} do
      session_2 = visit(new_session(browser), DynamicComponentBroadcastReceiverPage)
      wait_for_subscription(session_2, @broadcast_channel)

      session_1
      |> visit(DynamicComponentBroadcastSenderPage)
      |> click("#broadcast_button")

      assert_has(session_2, "#scenario_5", text: "delivered from broadcast")
    end

    # The counts are incremented before each swap, so a swapped-in component showing
    # count = 0 proves the previous module's state was discarded rather than reused.
    test "module swap under a cid resets state", %{page: page} do
      page
      |> visit(DynamicComponentSwapPage)
      |> assert_has("#component_7", text: "component_7 count = 0")
      |> click("#component_7_button")
      |> assert_has("#component_7", text: "component_7 count = 1")
      |> click("#swap_button")
      |> assert_has("#component_8", text: "component_8 count = 0")
      |> click("#component_8_button")
      |> assert_has("#component_8", text: "component_8 count = 1")
      |> click("#swap_button")
      |> assert_has("#component_7", text: "component_7 count = 0")
    end
  end

  describe "dynamic element" do
    test "tag name from state", %{page: page} do
      page
      |> visit(DynamicElementPage)
      |> assert_has("h2#scenario_1", text: "value_1")
    end

    test "event binding", %{page: page} do
      page
      |> visit(DynamicElementPage)
      |> assert_has("#scenario_2_result", text: "clicked? = false")
      |> click("#scenario_2")
      |> assert_has("#scenario_2_result", text: "clicked? = true")
    end
  end
end
