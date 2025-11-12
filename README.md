# MissionControl

A demo project exploring Ash Framework actions through functional programming concepts.

See the blog post [Ash Framework: A Closer Look at Actions](https://www.joekoski.com/blog/2025/11/09/ash-after_action.html)

This project demonstrates how Ash actions operate as Either pipelines, using superhero dispatch as a practical example of multi-resource operations, Kleisli composition, and closure under context.

## Prerequisites

* Elixir 1.15 or later
* Erlang/OTP compatible with your Elixir version

## Getting Started

1. Clone the repository and navigate to the project:

   ```bash
   git clone https://github.com/JKWA/ash-actions.git
   cd ash-actions
   ```

2. Install dependencies:

   ```bash
   mix setup
   ```

3. Start the Phoenix server:

   ```bash
   mix phx.server
   ```

   Or run inside IEx for interactive exploration:

   ```bash
   iex -S mix phx.server
   ```

4. Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Web UI

The app uses Ash Actions to enforce domain rules and report problems. A typical UI would hide invalid actions, this one does not. Instead, it allows all actions and reports domain errors.

## Learn More

* [Ash Framework](https://hexdocs.pm/ash)
* [Ash Framework Book](https://pragprog.com/titles/ldash/ash-framework/)
* [Funx](https://www.funxlib.com)
* [Advanced Functional Programming with Elixir](https://pragprog.com/titles/jkelixir/advanced-functional-programming-with-elixir/)
