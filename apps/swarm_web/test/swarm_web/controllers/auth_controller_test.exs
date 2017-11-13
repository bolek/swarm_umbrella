defmodule SwarmWeb.AuthControllerTest do
  use SwarmWeb.ConnCase

  @valid_credentials %{email: "t@t.com", password: "testtest"}
  @create_user_attrs %{name: "John", credential: @valid_credentials}
  @invalid_credentials %{email: "aaa", password: "bbb"}

  def fixture(:user) do
    {:ok, user} = Swarm.Accounts.create_user(@create_user_attrs)
    user
  end

  describe "requesting login page when not signed in" do
    test "show login page" do
      conn = get build_conn(), "/auth/identity"
      assert html_response(conn, 200) =~ "<h1>Sign in</h1>"
    end
  end

  describe "requesting login page when signed in" do
    setup [:create_user, :sign_in]

    test "redirect to root", %{conn: conn} do
      conn = get conn, "/auth/identity"
      assert redirected_to(conn) == "/"
    end
  end

  describe "when logging in using invalid email and password" do
    test "redirects to login page", %{conn: conn} do
      conn = post conn, auth_path(conn, :callback, :identity, @invalid_credentials)

      assert redirected_to(conn) == "/auth/identity?email=aaa"
    end
  end

  describe "when logging in using valid email and password" do
    setup [:create_user, :sign_in]
    test "redirects to root page", %{conn: conn} do
      conn = post conn, auth_path(conn, :callback, :identity, @valid_credentials)

      assert redirected_to(conn) == "/"
    end

    test "set current_user in session cookie", %{user: user, conn: conn} do
      conn = post conn, auth_path(conn, :callback, :identity, @valid_credentials)

      assert Plug.Conn.get_session(conn, :current_user) == user.id
    end
  end

  describe "when requesting to log out as a signed in user" do
    setup [:sign_in]

    test "deletes session", %{conn: conn} do
      conn = delete conn, auth_path(conn, :delete)
      conn = get conn, page_path(conn, :index)

      assert Plug.Conn.get_session(conn, :current_user) == nil
    end

    test "redirects to login page", %{conn: conn} do
      conn = delete conn, auth_path(conn, :delete)

      assert redirected_to(conn) == "/auth/identity"
    end
  end

  defp create_user(context) do
    context
    |> put_in([:user], fixture(:user))
  end
end
