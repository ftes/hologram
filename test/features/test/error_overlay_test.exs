defmodule HologramFeatureTests.ErrorOverlayTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.ErrorOverlayPage

  @dismiss_button "#hologram-uncaught-error-overlay button[aria-label='Dismiss']"
  @overlay "#hologram-uncaught-error-overlay"

  # Raises an uncaught error in the page, consuming the JavaScript error it logs
  # so that later interactions don't fail on it, and returns the session.
  defp raise_error(page) do
    assert_client_error page, RuntimeError, "overlaid error", fn ->
      page
      |> visit(ErrorOverlayPage)
      |> click_button("Raise error")
    end

    page
  end

  # Raises an error whose message runs over several lines, the same way.
  defp raise_function_clause_error(page) do
    expected_msg =
      ~r/^no function clause matching in HologramFeatureTests\.ErrorOverlayPage\.only_tuple\/1/

    assert_client_error page, FunctionClauseError, expected_msg, fn ->
      page
      |> visit(ErrorOverlayPage)
      |> click_button("No matching clause")
    end

    page
  end

  # Raises inside Elixir's own code, so the trace carries a frame from an
  # application other than the page's.
  defp raise_in_framework(page) do
    assert_client_error page, Enum.OutOfBoundsError, ~r/^out of bounds error/, fn ->
      page
      |> visit(ErrorOverlayPage)
      |> click_button("Raise in framework")
    end

    page
  end

  # Matches an element the overlay renders in the given tone, holding the given
  # text - which is what says a run of text was read the way it should be.
  defp toned(tone) do
    ".hologram-error-overlay__tone-#{tone}"
  end

  test "renders the error the page raised", %{page: page} do
    page
    |> raise_error()
    |> assert_has(@overlay)
    |> assert_text(@overlay, "Runtime Error")
    |> assert_text(@overlay, "** (RuntimeError) overlaid error")
  end

  # The overlay shows what the console shows, stacktrace included, so every frame
  # the error came through is named in the page as well.
  test "renders the stacktrace alongside the message", %{page: page} do
    page_module = inspect(ErrorOverlayPage)

    page
    |> raise_error()
    |> assert_text(@overlay, "#{page_module}.inner_fun/0")
    |> assert_text(@overlay, "#{page_module}.middle_fun/0")
    |> assert_text(@overlay, "#{page_module}.outer_fun/0")
    |> assert_text(@overlay, "#{page_module}.action/3")
  end

  test "sets the message apart from the frames it came through", %{page: page} do
    page
    |> raise_error()
    |> assert_has(toned("banner"), count: :any, text: "** (RuntimeError) overlaid error")
  end

  # A frame the page raised in is split, so where it happened reads apart from
  # what was running there.
  test "sets a frame's source location apart from what was running", %{page: page} do
    page
    |> raise_error()
    |> assert_has(toned("meta"), count: :any, text: "error_overlay_page.ex:")
    |> assert_has(toned("body"), count: :any, text: "#{inspect(ErrorOverlayPage)}.inner_fun/0")
  end

  # A frame from outside the page reads in one tone throughout, so the page's own
  # frames stand out of the run rather than having to be found in it. The page's
  # own frames name no application, so this needs an error raised where one does.
  test "reads a frame from outside the page in one tone", %{page: page} do
    page
    |> raise_in_framework()
    |> assert_has(toned("chrome"), count: :any, text: "(elixir ")
  end

  # A FunctionClauseError lists the arguments it was given, indenting them the
  # way a frame is indented. The listing is part of the message, so it has to
  # stay in the message rather than be read as the frames that follow it.
  test "keeps a message running over several lines in one piece", %{page: page} do
    page
    |> raise_function_clause_error()
    |> assert_has(toned("banner"), count: :any, text: "The following arguments were given to")
    |> assert_has(toned("banner"), count: :any, text: ":not_a_tuple")
  end

  test "dismisses on the dismiss button", %{page: page} do
    page
    |> raise_error()
    |> click(@dismiss_button)
    |> refute_has(@overlay)
  end

  test "dismisses on Escape", %{page: page} do
    page
    |> raise_error()
    |> send_keys("Escape")
    |> refute_has(@overlay)
  end
end
