import Config

config :fire_saga,
  openai_ttt: System.get_env("OPENAI_TTT_URL")
  openai_tti: System.get_env("OPENAI_TTI_URL"),
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  openai_org_id: System.get_env("OPENAI_ORG_ID")
