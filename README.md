# Haml2erb

A Ruby gem that converts HAML templates to ERB format using regex-based parsing for clean and readable output.

## Features

- Converts HAML syntax to ERB
- Handles complex HAML structures including nested elements, forms, and conditionals
- Preserves Ruby code blocks and expressions
- Supports HAML comments, CSS classes, IDs, and attributes
- Clean and readable ERB output with proper indentation
- Comprehensive test coverage for various HAML patterns

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'haml2erb', github: 'aki77/haml2erb'
```

And then execute:

```bash
bundle install
```

## Usage

### Command Line Interface

The gem provides a command-line tool for converting HAML files to ERB:

```bash
# Convert a HAML file to ERB
bundle exec haml2erb input.haml

# Convert with custom output file
bundle exec haml2erb input.haml -o output.erb

# Convert from stdin to stdout
cat input.haml | bundle exec haml2erb

# Convert from stdin to file
cat input.haml | bundle exec haml2erb -o output.erb

# Show help
bundle exec haml2erb --help

# Show version
bundle exec haml2erb --version
```

### Ruby API

You can also use the gem programmatically:

```ruby
require 'haml2erb'

haml_content = <<~HAML
  %div.container
    %h1 Hello World
    = user.name
    - if user.admin?
      %p.admin Admin user
HAML

erb_content = Haml2erb.convert(haml_content)
puts erb_content
```

### Supported HAML Features

- **Elements**: `%div`, `%p`, `%h1`, etc.
- **CSS Classes**: `.container`, `.card.shadow-lg`
- **IDs**: `#main`, `#sidebar`
- **Attributes**: `%div{:class => "test", :id => "main"}`
- **Ruby Output**: `= user.name`
- **Ruby Code**: `- if condition`
- **Escaped Output**: `&= content`
- **Unescaped Output**: `!= raw_html`
- **Comments**: `/ HTML comment`, `-# HAML comment`
- **Form helpers**: `simple_form_for`, `form.input`, etc.
- **Complex attributes**: `input_html`, `wrapper_html`, `data` attributes
- **Conditional blocks**: `if/else` statements
- **Nested structures**: Multi-level nesting with proper indentation

### Example Conversions

#### Basic Element
```haml
%div.card Hello World
```
↓
```erb
<div class="card">Hello World</div>
```

#### Form with Complex Attributes
```haml
= form.input :email, placeholder: 'Enter email', input_html: { class: 'form-control' }
```
↓
```erb
<%= form.input :email, placeholder: 'Enter email', input_html: { class: 'form-control' } %>
```

#### Conditional Block
```haml
- if user.admin?
  %p.admin Admin Panel
- else
  %p.user User Panel
```
↓
```erb
<% if user.admin? %>
  <p class="admin">Admin Panel</p>
<% else %>
  <p class="user">User Panel</p>
<% end %>
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Haml2erb project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/aki77/haml2erb/blob/main/CODE_OF_CONDUCT.md).
