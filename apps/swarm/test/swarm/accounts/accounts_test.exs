defmodule Swarm.AccountsTest do
  use Swarm.DataCase

  alias Swarm.Accounts

  describe "users" do
    alias Swarm.Accounts.User

    @valid_credential %{email: "dd@dd.com", password: "hokuspokus"}
    @valid_user_attrs %{name: "Donald Duck", credential: @valid_credential}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_user_attrs)
        |> Accounts.create_user()
      user
    end

    test "list_users/0 returns all users" do
      user =  user_fixture()
              |> Repo.preload(:credential)

      user_without_password = put_in(user.credential.password, nil)
      assert Accounts.list_users() == [user_without_password]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
        |> Repo.preload(:credential)

      user_without_password = put_in(user.credential.password, nil)
      assert Accounts.get_user!(user.id) == user_without_password
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_user_attrs)
      assert user.name == "Donald Duck"
    end

    test "create_user/1 with valid data with credential creates user" do
      assert{:ok, %User{} = user} = Accounts.create_user(@valid_user_attrs)
      user = Repo.preload(user, :credential)
      assert user.credential.email == "dd@dd.com"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture() |> Repo.preload(:credential)
      update_attrs = @update_attrs[:credential]
        |> put_in(%{id: user.credential.id, email: "abc@abc.com"})

      assert {:ok, user} = Accounts.update_user(user, update_attrs)

      user_without_password = put_in(user.credential.password, nil)
      assert %User{} = user_without_password
      assert user.name == "some updated name"

      user = Repo.preload(user, :credential)
      assert user.credential.email == "abc@abc.com"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
