# Dialyzer warnings to ignore
# See: https://github.com/jeremyjh/dialyxir#ignore-warnings

# Mix.Task behaviour warnings are false positives - Mix is available at compile time
[
  # Ignore Mix.Task behaviour callback warnings in mix tasks
  ~r/callback_info_missing.*Mix\.Task/,
  ~r/Function Mix\.Task/,
  ~r/Function Mix\.Shell/,
  ~r/Function Mix\.CLI/
]
