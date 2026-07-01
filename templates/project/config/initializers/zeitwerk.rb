# frozen_string_literal: true

# Collapse app/domains/<context>/{domain,application,infrastructure,interface}
# so Billing::Invoice lives at app/domains/billing/domain/invoice.rb
# See docs/standards/stacks/rails8/ddd/rails-package-layout.md

Rails.application.config.to_prepare do
  loader = Rails.autoloaders.main

  %w[domain application infrastructure interface].each do |layer|
    Dir[Rails.root.join("app/domains/*/#{layer}")].each do |path|
      loader.collapse(path)
    end
  end

  %w[adapters repositories read_models].each do |sub|
    Dir[Rails.root.join("app/domains/*/infrastructure/#{sub}")].each do |path|
      loader.collapse(path)
    end
  end
end
