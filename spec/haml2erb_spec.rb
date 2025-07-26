# rubocop:disable Metrics/BlockLength
# frozen_string_literal: true

RSpec.describe Haml2erb do
  it "has a version number" do
    expect(Haml2erb::VERSION).not_to be nil
  end

  describe ".convert" do
    it "handles basic element syntax" do
      haml = "%div Hello"
      expected = "<div>Hello</div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles CSS class shorthand" do
      haml = ".box Content"
      expected = "<div class=\"box\">Content</div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles ID selector syntax" do
      haml = "#main Content"
      expected = "<div id=\"main\">Content</div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes element attributes" do
      haml = "%div{:class => \"test\", :id => \"main\"} Content"
      expected = "<div class=\"test\" id=\"main\">Content</div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles Ruby output expressions" do
      haml = "= user.name"
      expected = "<%= user.name %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes Ruby code blocks" do
      haml = "- if user"
      expected = "<% if user %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles escaped output syntax" do
      haml = "&= content"
      expected = "<%= content %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes unescaped output" do
      haml = "!= html_content"
      expected = "<%== html_content %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles HTML comment syntax" do
      haml = "/ Comment"
      expected = "<!-- Comment -->\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes ERB comment blocks" do
      haml = "-# This is a HAML comment"
      expected = "<%# This is a HAML comment %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "preserves plain text" do
      haml = "Plain text"
      expected = "Plain text\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles nested structure" do
      haml = <<~HAML
        %div
          %p Content
      HAML
      expected = <<~ERB
        <div>
          <p>Content</p>
        </div>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles locals declaration" do
      haml = "-# locals: (user:, item:)"
      result = Haml2erb.convert(haml)
      expect(result).to eq("<%# locals: (user:, item:) %>\n")
    end

    it "supports form helper methods" do
      haml = <<~HAML
        = form_for user do |form|
          = form.input :name
      HAML
      expected = <<~ERB
        <%= form_for user do |form| %>
          <%= form.input :name %>
        <% end %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles multiple CSS classes" do
      haml = ".card.border.active"
      expected = "<div class=\"card border active\"></div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes form input attributes" do
      haml = "= form.input :email, placeholder: 'Email', required: true"
      expected = "<%= form.input :email, placeholder: 'Email', required: true %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles conditional logic blocks" do
      haml = <<~HAML
        - if user
          %p Found
        - else
          %p Not found
      HAML
      expected = <<~ERB
        <% if user %>
          <p>Found</p>
        <% else %>
          <p>Not found</p>
        <% end %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "supports form collection options" do
      haml = "= form.select :status, options"
      expected = "<%= form.select :status, options %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles form wrapper HTML options" do
      haml = "= form.input :date, wrapper_html: { class: 'wrapper' }"
      expected = "<%= form.input :date, wrapper_html: { class: 'wrapper' } %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes textarea with attributes" do
      haml = "= form.text_area :content, rows: 5"
      expected = "<%= form.text_area :content, rows: 5 %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles link helpers with classes" do
      haml = "= link_to 'Cancel', path, class: 'btn'"
      expected = "<%= link_to 'Cancel', path, class: 'btn' %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes button helpers with data attributes" do
      haml = "= button_to path, method: :delete, data: { confirm: 'Sure?' }"
      expected = "<%= button_to path, method: :delete, data: { confirm: 'Sure?' } %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles complex CSS selector syntax" do
      haml = ".box.large.active"
      expected = "<div class=\"box large active\"></div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes form submit elements" do
      haml = "= form.submit class: 'btn'"
      expected = "<%= form.submit class: 'btn' %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles nested form elements" do
      haml = <<~HAML
        = form_for user do |form|
          .group
            = form.input :name
          .actions
            = form.submit
      HAML
      expected = <<~ERB
        <%= form_for user do |form| %>
          <div class="group">
            <%= form.input :name %>
          </div>
          <div class="actions">
            <%= form.submit %>
          </div>
        <% end %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "supports conditional logic with method calls" do
      haml = <<~HAML
        - if user.active? && can_edit?
          = link_to 'Edit', edit_path
      HAML
      expected = <<~ERB
        <% if user.active? && can_edit? %>
          <%= link_to 'Edit', edit_path %>
        <% end %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles button helpers with block content" do
      haml = <<~HAML
        %li
          = button_to path, method: :delete do
            Logout
      HAML
      expected = <<~ERB
        <li>
          <%= button_to path, method: :delete do %>
            Logout
          <% end %>
        </li>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes conditional blocks with nested elements" do
      haml = <<~HAML
        - if user.admin?
          %li
            %h2.title Admin
      HAML
      expected = <<~ERB
        <% if user.admin? %>
          <li>
            <h2 class="title">Admin</h2>
          </li>
        <% end %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles nested elements with data attributes" do
      haml = <<~HAML
        .menu{ 'data-id': 'nav' }
          .btn{ role: 'button' }
            %span.icon
            %span.text= user.name
      HAML
      expected = <<~ERB
        <div class="menu" data-id="nav">
          <div class="btn" role="button">
            <span class="icon"></span>
            <span class="text"><%= user.name %></span>
          </div>
        </div>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes doctype and HTML structure" do
      haml = <<~HAML
        !!!
        %html
          %head
      HAML
      expected = <<~ERB
        <!DOCTYPE html>
        <html>
          <head></head>
        </html>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles Ruby filter blocks" do
      haml = <<~HAML
        :ruby
          value = item.name
      HAML
      expected = <<~ERB
        <%
          value = item.name
        %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes locals declaration with parameters" do
      haml = "-# locals: (user:, item: nil)"
      expected = "<%# locals: (user:, item: nil) %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles nested conditional logic" do
      haml = <<~HAML
        - if user.new_record?
          - if user.admin?
            = form.input :name
          - else
            = form.input :name
        - else
          = form.input :name
      HAML
      expected = <<~ERB
        <% if user.new_record? %>
          <% if user.admin? %>
            <%= form.input :name %>
          <% else %>
            <%= form.input :name %>
          <% end %>
        <% else %>
          <%= form.input :name %>
        <% end %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "supports complex form structures with conditionals" do
      haml = <<~HAML
        %div
          = form_for record do |form|
            .form-body
              - if record.new_record?
                - if user.admin?
                  = form.select :category_id, options
                - else
                  = form.hidden_field :category_id
              - else
                = form.hidden_field :category_id

              .actions
                = form.submit
      HAML
      expected = <<~ERB
        <div>
          <%= form_for record do |form| %>
            <div class="form-body">
              <% if record.new_record? %>
                <% if user.admin? %>
                  <%= form.select :category_id, options %>
                <% else %>
                  <%= form.hidden_field :category_id %>
                <% end %>
              <% else %>
                <%= form.hidden_field :category_id %>

              <% end %>
              <div class="actions">
                <%= form.submit %>
              </div>
            </div>
          <% end %>
        </div>
      ERB
      expect(Haml2erb.convert(haml)).to eq("#{expected.strip}\n")
    end

    it "processes elements with helper methods in attributes" do
      haml = <<~HAML
        %ul{ class: class_names(menu_classes) }
          = content
      HAML
      expected = <<~ERB
        <ul class="<%= class_names(menu_classes) %>">
          <%= content %>
        </ul>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles multiline form input syntax" do
      haml = <<~HAML
        = form.input :value,
          collection: options,
          include_blank: '----'
      HAML
      expected = "<%= form.input :value, collection: options, include_blank: '----' %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes table elements with accessibility attributes" do
      haml = "%td{ 'aria-label': User.human_attribute_name(:name) }= user.name"
      expected = "<td aria-label=\"<%= User.human_attribute_name(:name) %>\"><%= user.name %></td>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles multiline Ruby interpolation" do
      haml = "%strong\n  \#{name}"
      expected = "<strong>\n  <%= name %>\n</strong>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles inline Ruby interpolation in text content" do
      haml = '%span created_at: #{l(post.created_at, format: :long)}' # rubocop:disable Lint/InterpolationCheck
      expected = "<span>created_at: <%= l(post.created_at, format: :long) %></span>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles instance variables in element attributes" do
      haml = "%webauthn{ options: @webauthn_options }"
      expected = "<webauthn options=\"<%= @webauthn_options %>\"></webauthn>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles meta tags with multiple attributes" do
      haml = "%meta{name: 'viewport', content: 'width=device-width, initial-scale=1.0'}"
      expected = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "supports Tailwind CSS bracket notation" do
      haml = ".test{ class: 'max-w-[100rem]' }"
      expected = "<div class=\"test max-w-[100rem]\"></div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes nested data attribute structures" do
      haml = "%div{ data: { test_id: 'test' } }"
      expected = "<div data-test-id=\"test\"></div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles dynamic class merging with data attributes" do
      haml = <<~HAML
        .alert{
          class: class_name,
          'data-controller': 'alert',
        }
          test
      HAML
      expected = "<div class=\"alert <%= class_name %>\" data-controller=\"alert\">test</div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles elements with Ruby expressions and escaped characters" do
      haml = <<~HAML
        %span
          = started_at
          \\-
          = ended_at
      HAML
      expected = <<~ERB
        <span>
          <%= started_at %>
          -
          <%= ended_at %>
        </span>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes Ruby output with inline comments" do
      haml = "= test # test"
      expected = "<%= test %> <%# test %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles elements with constant array access in attributes" do
      haml = "%div{ class: Test::NAMES[test&.id] }"
      expected = "<div class=\"<%= Test::NAMES[test&.id] %>\"></div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes render helpers with content methods" do
      haml = '= render Component.new.with_content("title | #{@subtitle}")'
      expected = "<%= render Component.new.with_content(\"title | \#{@subtitle}\") %>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles consecutive Ruby code and output blocks" do
      haml = <<~HAML
        - breadcrumb :test

        = render Component.new do
          test
      HAML
      expected = <<~ERB
        <% breadcrumb :test %>

        <%= render Component.new do %>
          test
        <% end %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles iteration blocks with element output" do
      haml = <<~HAML
        - @posts.each do |post|
          %span= post.title
      HAML
      expected = <<~ERB
        <% @posts.each do |post| %>
          <span><%= post.title %></span>
        <% end %>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "processes data attributes with Ruby interpolation" do
      haml = '%tr{ data: { test_id: "test_#{id}" } }'
      expected = "<tr data-test-id=\"test_<%= id %>\"></tr>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles iconify-icon with inline attribute" do
      haml = "%iconify-icon{ inline: true }"
      expected = "<iconify-icon inline></iconify-icon>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles class selector with Ruby output directly after =" do
      haml = ".text-pre-wrap= t('some.key', default: 'Default text')"
      expected = "<div class=\"text-pre-wrap\"><%= t('some.key', default: 'Default text') %></div>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles element with class selector and Ruby output" do
      haml = "%h2.mb-4= t('another.key', default: 'Another default')"
      expected = "<h2 class=\"mb-4\"><%= t('another.key', default: 'Another default') %></h2>\n"
      expect(Haml2erb.convert(haml)).to eq(expected)
    end

    it "handles element with Ruby output followed by another element" do
      haml = <<~HAML
        %h2= t('views.users.sessions.new.title', default: 'ログイン')

        .text-pre-wrap= tt('views.users.sessions.new.help_text')
      HAML
      expected = <<~ERB
        <h2><%= t('views.users.sessions.new.title', default: 'ログイン') %></h2>

        <div class="text-pre-wrap"><%= tt('views.users.sessions.new.help_text') %></div>
      ERB
      expect(Haml2erb.convert(haml)).to eq(expected)
    end
  end
end
# rubocop:enable Metrics/BlockLength
