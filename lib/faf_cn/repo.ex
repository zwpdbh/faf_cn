defmodule FafCn.Repo do
  use Ecto.Repo,
    otp_app: :faf_cn,
    adapter: Ecto.Adapters.Postgres
end
