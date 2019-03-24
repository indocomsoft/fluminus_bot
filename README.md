# FluminusBot

[![Build Status](https://travis-ci.com/indocomsoft/fluminus_bot.svg?branch=master)](https://travis-ci.com/indocomsoft/fluminus_bot)
[![Coverage Status](https://coveralls.io/repos/github/indocomsoft/fluminus_bot/badge.svg?branch=master)](https://coveralls.io/github/indocomsoft/fluminus_bot?branch=master)

<sup><sub>F LumiNUS! IVLE ftw! Why fix what ain't broken?!</sub></sup>


I try to keep to best coding practices and use as little dependencies as possible. Do let me know if you have any suggestions!

PR's are welcome.

## Prerequisites
1. Elixir (tested with version 1.8, but anything above 1.6 should work)
1. PostgreSQL (tested with version 10)
1. A Telegram Bot token

## Installation
1. Clone this repo.
1. Copy `config/secrets.exs.example` to `config/secrets.exs`, and fill in the appropriate setting.
1. If necessary, change the bot name in `lib/fluminus_bot.ex`, specifically the `@bot` module attribute.
1. Run `mix start`.

The docs can be found at [https://hexdocs.pm/fluminus_bot](https://hexdocs.pm/fluminus_bot).
