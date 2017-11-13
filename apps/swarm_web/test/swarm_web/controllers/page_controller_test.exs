defmodule SwarmWeb.PageControllerTest do
  use SwarmWeb.ConnCase

  @create_user_attrs %{name: "John", credential: %{email: "t@t.com", password: "testtest"}}

  def fixture(:user) do
    {:ok, user} = Swarm.Accounts.create_user(@create_user_attrs)
    user
  end

  describe "when no user logged in" do
    test "Get /", %{conn: conn} do
      conn = get conn, page_path(conn, :index)
      assert redirected_to(conn) =~ "/auth/identity"
    end
  end

  describe "when a user logged in" do
    setup [:create_user, :sign_in]

    test "Get /", %{conn: conn, user: user} do
      conn = get conn, page_path(conn, :index)
      assert html_response(conn, 200) =~ "Hello #{user.name}"
    end
  end

  defp create_user(context) do
    context
    |> put_in([:user], fixture(:user))
  end
end
