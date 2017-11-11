defmodule Swarm.Accounts.Credential do
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Accounts.{Credential, User}


  schema "credentials" do
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(%Credential{} = credential, attrs) do
    credential
    |> cast(attrs, [:password, :email])
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 8)
    |> encrypt_password()
    |> unique_constraint(:email)
  end

  defp encrypt_password(changeset) do
    if (password = get_change(changeset, :password)) do
      changeset
      |> put_change(:encrypted_password, Comeonin.Argon2.hashpwsalt(password))
    else
      changeset
    end
  end
end
