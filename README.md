# farol

Accessibility testing for Phoenix LiveView, in pure Elixir.

*farol* is portuguese for lighthouse, and Lighthouse is the audit tool most
of the web knows. This one speaks LiveView natively: it knows what
`phx-click` on a `<div>` means, and it explains every finding instead of
just pointing at it. No node, no browser, no axe-core port. Just Elixir,
running inside the test suite you already have.

```elixir
test "user card is accessible" do
  html = render_component(&user_card/1, user: user)
  assert_accessible html
end
```

When it fails, it teaches:

```
x [img-alt] <img src="avatar.jpg"> has no alt text
  wcag 1.1.1 (level a) - error

  why: screen readers announce the filename ("i m g underscore avatar
    dot jay peg") or silence. 2.2 billion people live with some form of
    vision impairment; alt text is how the image reaches them.

  fix: add alt="..." describing what the image conveys - or alt=""
    (empty) when the image is purely decorative, so screen readers skip
    it.
```

Every finding carries three layers: what was found, why it matters to
humans, and how to fix it. The "why" is written for the developer reading
a failing test at 5pm, not for a compliance auditor.

## installation

```elixir
def deps do
  [
    {:farol, "~> 0.1", only: :test}
  ]
end
```

Then import the assertion in your test case (or in `ConnCase`/`DataCase`
template, to have it everywhere):

```elixir
import Farol.Assertions
```

## using it

`assert_accessible/2` takes any rendered HTML string, which is exactly
what `render_component/2` and `render/1` return in LiveView tests:

```elixir
test "settings page is accessible" do
  {:ok, view, html} = live(conn, "/settings")
  assert_accessible html
end
```

Escape hatches are explicit on purpose, so exceptions stay greppable in
code review:

```elixir
assert_accessible html, except: ["landmark-regions"]
assert_accessible html, only: [:img_alt, :label_association]
```

Want the raw findings instead of an assertion? `Farol.check/2` returns
them as data, and `Farol.Report.format/1` renders the same report the
assertion prints.

## the rule catalog

The catalog is the product. Every rule is a plain module implementing the
`Farol.Rule` behaviour, which makes the catalog the extension point too.

**structure**

| rule | wcag | severity | what it checks |
| --- | --- | --- | --- |
| `img-alt` | 1.1.1 | error | images without alt text (or explicit decorative marker) |
| `label-association` | 1.3.1 | error | form controls without a programmatic label |
| `landmark-regions` | 1.3.1 | warning | documents with no `<main>` landmark |
| `heading-order` | 1.3.1 | warning | skipped heading levels (h1 straight to h3) |
| `duplicate-id` | 4.1.1 | error | ids repeated in the document |
| `html-lang` | 3.1.1 | error | `<html>` without a declared language |
| `document-title` | 2.4.2 | warning | documents with a missing or empty `<title>` |

**aria validity**

| rule | wcag | severity | what it checks |
| --- | --- | --- | --- |
| `valid-role` | 4.1.2 | error | role values outside the ARIA spec |
| `valid-aria-attr` | 4.1.2 | error | misspelled or invented aria attributes |
| `no-aria-on-hidden` | 4.1.2 | warning | aria on elements nothing can announce |

**accessible names**

| rule | wcag | severity | what it checks |
| --- | --- | --- | --- |
| `button-name` | 4.1.2 | error | buttons (including icon buttons) with no name |
| `link-name` | 2.4.4 | error | links with no name |
| `iframe-title` | 4.1.2 | error | iframes without a title |

**liveview-aware** (the reason farol exists; nobody else checks these)

| rule | wcag | severity | what it checks |
| --- | --- | --- | --- |
| `phx-click-interactive` | 2.1.1 | error | `phx-click` on elements keyboard users cannot reach |
| `toggle-aria-pairing` | 4.1.2 | warning | `JS.toggle`/`JS.show`/`JS.hide` triggers without `aria-expanded`/`aria-controls` |
| `focus-after-patch` | 2.4.3 | warning | `phx-update` containers that can swallow focus, with no hook to restore it |
| `live-region-usage` | 4.1.3 | warning | flash containers outside an `aria-live` region |

**contrast (opt-in)**

| rule | wcag | severity | what it checks |
| --- | --- | --- | --- |
| `contrast-token` | 1.4.3 | error | inline colors below WCAG AA ratios, resolved through your design tokens |

## contrast, driven by your design tokens

`contrast-token` only runs when you declare a token map, because without
it the rule cannot know what your color names mean. Declare it once and
your design system becomes the test fixture:

```elixir
config :farol, :tokens, %{
  "bg" => "#000A0F",
  "fg" => "#F7F7FF",
  "accent" => "#9655FF"
}
```

Inline styles then check against WCAG AA: 4.5:1 for text, 3:1 for large
text (24px, or 18.66px bold). Values can be hex literals, token names, or
`var(--token)` references. For the zeetech palette above, farol can tell
you that `#9655FF` on `#000A0F` sits at about 4.8:1, and show the math.

Deliberate scope line: tokens plus inline styles only. Resolving CSS
classes means writing a CSS engine, and that is a later conversation.

## writing your own rules

A rule is a plain module with a behaviour, no macros:

```elixir
defmodule MyApp.Rules.NoTargetBlank do
  @behaviour Farol.Rule

  alias Farol.{Finding, Node}

  def id, do: "no-target-blank"
  def wcag, do: "3.2.5"
  def level, do: "a"
  def severity, do: :warning
  def why, do: "new tabs break the back button and disorient screen reader users."
  def fix, do: "drop target=\"_blank\", or warn in the link text that it opens a new tab."

  def check(nodes) do
    nodes
    |> Node.find(&(Node.attr(&1, "target") == "_blank"))
    |> Enum.map(fn node ->
      %Finding{
        rule: id(),
        wcag: wcag(),
        level: level(),
        severity: severity(),
        message: "#{Node.snippet(node)} opens a new tab without warning",
        snippet: Node.snippet(node)
      }
    end)
  end
end
```

Rules receive the parsed document as `Farol.Node` trees and return
findings. They never raise and never do IO, which keeps them trivially
testable: pass a string through `Farol.check/2` with `only:` and assert on
the findings.

## how it works inside

Two engines, one rule catalog. The runtime engine (this release) parses
rendered HTML into a normalized `Farol.Node` tree via `lazy_html` (the
lexbor engine). The static engine (planned) will walk the HEEx tokenizer
output at compile time. Both feed the same node struct into the same rule
modules, so the catalog never forks.

Deliberate non-goals: not a component library (farol grades components, it
does not ship them), not a browser driver, not a screen reader simulator.
Structural checks only, which is exactly what fits in a test suite.

## roadmap

- **0.1** (this): runtime engine, 18 rules, ExUnit assertions, terminal
  report, zero-config default.
- **0.2**: HEEx static analysis, `mix farol`, SARIF output for GitHub code
  scanning, source locations.
- **0.3**: `farol_liveview` package with patch-cycle focus tracking and
  per-route audit mode.
- **1.0**: rule api freeze, WCAG 2.2 AA coverage target.

## license

MIT. Built by [zeetech](https://zeetech.io), de minoria pra minoria.
