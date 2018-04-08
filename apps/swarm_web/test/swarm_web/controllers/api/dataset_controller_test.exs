defmodule SwarmWeb.Api.DatasetControllerTest do
  use SwarmWeb.ApiCase
  use SwarmEngine.DataCase

  @create_attrs %{
    "name" => "My Dataset",
    "source" => %{
      "type" => "LocalFile",
      "path" => "tmp.txt"
    },
    "decoder" => %{
      "type" => "CSV",
      "headers" => true,
      "separator" => ",",
      "delimiter" => "/n"
    }
  }

  @invalid_attrs %{name: nil}

  def fixture(:dataset) do
    {:ok, dataset} = SwarmEngine.create_dataset(@create_attrs)
    dataset
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "GET /index" do
    test "lists all datasets", context do
      %{conn: conn} = sign_in(context)

      conn = get(conn, dataset_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "unauthenticated access", %{conn: conn} do
      conn = get(conn, dataset_path(conn, :index))
      assert json_response(conn, 401)["message"] == "unauthenticated"
    end
  end

  describe "create dataset" do
    setup [:sign_in]

    test "renders dataset when data is valid", %{conn: conn} do
      res = post(conn, dataset_path(conn, :create), dataset: @create_attrs)
      assert %{"id" => id} = json_response(res, 201)["data"]

      res = get(conn, dataset_path(conn, :show, id))

      assert json_response(res, 200)["data"] == %{
               "id" => id,
               "name" => "My Dataset",
               "decoder" => %{
                 "type" => "CSV",
                 "delimiter" => "/n",
                 "headers" => true,
                 "separator" => ","
               },
               "source" => %{"type" => "LocalFile", "path" => "tmp.txt"}
             }
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, dataset_path(conn, :create), dataset: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
