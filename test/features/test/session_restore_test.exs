defmodule HologramFeatureTests.SessionRestoreTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.SessionRestore.AccountPage
  alias HologramFeatureTests.SessionRestore.LoginPage
  alias HologramFeatureTests.SessionRestore.ProtectedPage

  # The marker is state only the account page holds, so Back shows it only by restoring the page
  # as it was left. Each command's result is waited for before the next step, so that the identity
  # it leaves is the one the browser holds.

  # A page that is rebuilt or reloaded after a #fragment click is, a moment after the click, once
  # the handler's storage writes are done. So the page is given that moment before the marker is
  # checked.
  defp keep_marker(page) do
    page
    |> sleep(1_000)
    |> assert_text("#marker", "set")
  end

  # Logs in as Alice, opens the account page with a marker put on it, and leaves it for the login
  # page through a link.
  defp leave_marked_account_page(page) do
    page
    |> visit(LoginPage)
    |> log_in("Log in as Alice", "alice")
    |> click_link("Account page link")
    |> assert_page(AccountPage)
    |> assert_text("#user", "alice")
    |> put_marker()
    |> click_link("Login page link")
    |> assert_page(LoginPage)
  end

  defp log_in(page, button_text, user) do
    page
    |> click_button(button_text)
    |> assert_text("#result", "logged in as #{user}")
  end

  defp log_out(page) do
    page
    |> click_button("Log out")
    |> assert_text("#result", "logged out")
  end

  defp put_marker(page) do
    page
    |> click_button("Put marker")
    |> assert_text("#marker", "set")
  end

  describe "the user did not change" do
    test "restores the page as it was left", %{page: page} do
      page
      |> leave_marked_account_page()
      |> go_back()
      |> assert_page(AccountPage)
      |> assert_text("#user", "alice")
      |> assert_text("#marker", "set")
    end

    # Writes to the session that leave the identity alone, a cart for one, don't end restores.
    test "restores the page as it was left after a session write", %{page: page} do
      page
      |> leave_marked_account_page()
      |> click_button("Put cart item")
      |> assert_text("#result", "cart updated")
      |> go_back()
      |> assert_page(AccountPage)
      |> assert_text("#user", "alice")
      |> assert_text("#marker", "set")
    end

    # A page the browser loaded is stamped with the identity its document was rendered for.
    test "restores a page left after a full page load as it was left", %{page: page} do
      page
      |> visit(LoginPage)
      |> log_in("Log in as Alice", "alice")
      |> click_link("Account page link")
      |> assert_page(AccountPage)
      |> reload()
      |> assert_page(AccountPage)
      |> put_marker()
      |> click_link("Login page link")
      |> assert_page(LoginPage)
      |> go_back()
      |> assert_page(AccountPage)
      |> assert_text("#user", "alice")
      |> assert_text("#marker", "set")
    end
  end

  describe "the user changed" do
    test "renders the page for the user logged in now after a user switch", %{
      page: page
    } do
      page
      |> leave_marked_account_page()
      |> log_in("Log in as Bob", "bob")
      |> go_back()
      |> assert_page(AccountPage)
      |> assert_text("#user", "bob")
      |> assert_text("#marker", "none")
    end

    test "renders the page for the current visitor after a logout", %{page: page} do
      page
      |> leave_marked_account_page()
      |> log_out()
      |> go_back()
      |> assert_page(AccountPage)
      |> assert_text("#user", "anonymous")
      |> assert_text("#marker", "none")
    end

    # The reloaded document keeps the history entries the one before it pushed, so Back reaches
    # a snapshot the earlier document took, which is restored only for the identity it was taken
    # for.
    test "renders the page for the current visitor when Back goes past a full page load", %{
      page: page
    } do
      page
      |> leave_marked_account_page()
      |> log_out()
      |> reload()
      |> assert_page(LoginPage)
      # The document before the reload shows "logged out".
      |> assert_text("#result", "none")
      |> go_back()
      |> assert_page(AccountPage)
      |> assert_text("#user", "anonymous")
      |> assert_text("#marker", "none")
    end

    # The page is asked for as a fresh visit asks for it, so its middleware runs.
    test "redirects from a page that requires a login", %{page: page} do
      page
      |> visit(LoginPage)
      |> log_in("Log in as Alice", "alice")
      |> click_link("Protected page link")
      |> assert_page(ProtectedPage)
      |> put_marker()
      |> click_link("Login page link")
      |> assert_page(LoginPage)
      |> log_out()
      |> go_back()
      |> assert_page(LoginPage)
      # The login page that was left shows "logged out", so only a fresh one, from the redirect,
      # shows "none".
      |> assert_text("#result", "none")
    end
  end

  describe "#fragment links" do
    test "keep the page as it is when clicked", %{page: page} do
      page
      |> visit(LoginPage)
      |> log_in("Log in as Alice", "alice")
      |> click_link("Account page link")
      |> assert_page(AccountPage)
      |> put_marker()
      |> click_link("Bottom link")
      |> assert_url(~r/#bottom$/)
      |> keep_marker()
      |> assert_page(AccountPage)
      |> assert_text("#user", "alice")
      |> assert_text("#marker", "set")
    end

    # The page path an entry with no id is compared with comes from the document's boot here.
    test "keep a page the browser loaded as it is when clicked", %{page: page} do
      page
      |> visit(LoginPage)
      |> log_in("Log in as Alice", "alice")
      |> visit(AccountPage)
      |> assert_text("#user", "alice")
      |> put_marker()
      |> click_link("Bottom link")
      |> assert_url(~r/#bottom$/)
      |> keep_marker()
      |> assert_page(AccountPage)
      |> assert_text("#marker", "set")
    end

    test "restore their page as it was left on Back from another page", %{page: page} do
      page
      |> visit(LoginPage)
      |> log_in("Log in as Alice", "alice")
      |> click_link("Account page link")
      |> assert_page(AccountPage)
      |> put_marker()
      |> click_link("Bottom link")
      |> assert_url(~r/#bottom$/)
      |> click_link("Login page link")
      |> assert_page(LoginPage)
      |> go_back()
      |> assert_page(AccountPage)
      |> assert_text("#user", "alice")
      |> assert_text("#marker", "set")
    end

    test "render their page for the current visitor on Back after a logout", %{
      page: page
    } do
      page
      |> visit(LoginPage)
      |> log_in("Log in as Alice", "alice")
      |> click_link("Account page link")
      |> assert_page(AccountPage)
      |> put_marker()
      |> click_link("Bottom link")
      |> assert_url(~r/#bottom$/)
      |> click_link("Login page link")
      |> assert_page(LoginPage)
      |> log_out()
      |> go_back()
      |> assert_page(AccountPage)
      |> assert_text("#user", "anonymous")
      |> assert_text("#marker", "none")
    end
  end
end
