defmodule SwarmWeb.Api.UserControllerTest do
  use SwarmWeb.ApiCase

  alias Swarm.Accounts
  alias Swarm.Accounts.User

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:sign_in]

    test "lists all users", %{conn: conn, user: user} do
      res = get conn, user_path(conn, :index)
      assert json_response(res, 200)["data"] == [%{"id" => user.id, "name" => user.name}]
    end
  end

  describe "create user" do
    setup [:sign_in]

    test "renders user when data is valid", %{conn: conn} do
      res = post conn, user_path(conn, :create), user: @create_attrs
      assert %{"id" => id} = json_response(res, 201)["data"]

      res = get conn, user_path(conn, :show, id)
      assert json_response(res, 200)["data"] == %{
        "id" => id,
        "name" => "some name"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      res = post conn, user_path(conn, :create), user: @invalid_attrs
      assert json_response(res, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user, :sign_in]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      res = put conn, user_path(conn, :update, user), user: @update_attrs
      assert %{"id" => ^id} = json_response(res, 200)["data"]

      res = get conn, user_path(conn, :show, id)
      assert json_response(res, 200)["data"] == %{
        "id" => id,
        "name" => "some updated name"}
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      res = put conn, user_path(conn, :update, user), user: @invalid_attrs
      assert json_response(res, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user, :sign_in]

    test "deletes chosen user", %{conn: conn, user: user} do
      res = delete conn, user_path(conn, :delete, user)
      assert response(res, 204)
      assert_error_sent 404, fn ->
        get conn, user_path(conn, :show, user)
      end
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
