#!/bin/bash

echo "=== Installing Rails Country App ==="

# Install dependencies
sudo yum install -y mysql-devel
gem install rails bundler

# Create Rails app in current directory
rails new . --database=mysql --skip-git --force

# Create .env
cat > .env << 'EOF'
DB_USERNAME=admin
DB_PASSWORD=C]3Ws8ztuKp0|wPD7j8#Kut-x!T#
DB_HOST=capstone1.cl2sqcgm6jdi.us-east-1.rds.amazonaws.com
EOF

echo ".env" >> .gitignore

# Update Gemfile
cat >> Gemfile << 'EOF'

gem 'kaminari'
gem 'dotenv-rails', groups: [:development, :test]
gem 'bootstrap', '~> 5.3.0'
gem 'sassc-rails'
EOF

bundle install

# Setup database config
cat > config/database.yml << 'EOF'
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV['DB_USERNAME'] %>
  password: <%= ENV['DB_PASSWORD'] %>
  host: <%= ENV['DB_HOST'] %>

development:
  <<: *default
  database: countries

test:
  <<: *default
  database: countries_test

production:
  <<: *default
  database: countries
EOF

# Generate files
rails generate model Country --skip-migration
rails generate controller Countries index show

# Country model
cat > app/models/country.rb << 'EOF'
class Country < ApplicationRecord
  self.table_name = 'country'
  self.primary_key = 'Code'
end
EOF

# Controller
cat > app/controllers/countries_controller.rb << 'EOF'
class CountriesController < ApplicationController
  def index
    @countries = Country.all.order(:Name)
    if params[:search].present?
      @countries = @countries.where("Name LIKE ?", "%#{params[:search]}%")
    end
    @countries = @countries.page(params[:page]).per(25)
  end

  def show
    @country = Country.find(params[:id])
  end
end
EOF

# Routes
cat > config/routes.rb << 'EOF'
Rails.application.routes.draw do
  root 'countries#index'
  resources :countries, only: [:index, :show]
end
EOF

# Bootstrap setup
mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss 2>/dev/null
echo '@import "bootstrap";' > app/assets/stylesheets/application.scss

# Views
mkdir -p app/views/countries

cat > app/views/countries/index.html.erb << 'EOF'
<div class="container my-4">
  <h1>Countries Database</h1>
  <%= form_with(url: countries_path, method: :get, class: "my-3") do %>
    <%= text_field_tag :search, params[:search], class: "form-control d-inline-block w-auto", placeholder: "Search..." %>
    <%= submit_tag "Search", class: "btn btn-primary" %>
    <%= link_to "Clear", countries_path, class: "btn btn-secondary" %>
  <% end %>
  <table class="table table-striped">
    <thead class="table-dark">
      <tr><th>Code</th><th>Name</th><th>Continent</th><th>Population</th><th></th></tr>
    </thead>
    <tbody>
      <% @countries.each do |c| %>
        <tr>
          <td><%= c.Code %></td><td><%= c.Name %></td><td><%= c.Continent %></td>
          <td><%= number_with_delimiter(c.Population) %></td>
          <td><%= link_to "View", country_path(c.Code), class: "btn btn-sm btn-info" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
  <%= paginate @countries %>
</div>
EOF

cat > app/views/countries/show.html.erb << 'EOF'
<div class="container my-4">
  <h1><%= @country.Name %></h1>
  <div class="card">
    <div class="card-body">
      <p><strong>Code:</strong> <%= @country.Code %></p>
      <p><strong>Continent:</strong> <%= @country.Continent %></p>
      <p><strong>Region:</strong> <%= @country.Region %></p>
      <p><strong>Population:</strong> <%= number_with_delimiter(@country.Population) %></p>
      <p><strong>Surface Area:</strong> <%= number_with_delimiter(@country.SurfaceArea) %> km²</p>
      <%= link_to "Back", countries_path, class: "btn btn-secondary" %>
    </div>
  </div>
</div>
EOF

# Cloud9 config
sed -i '/^end$/i \  config.hosts << /.*\\.amazonaws\\.com/' config/environments/development.rb

# Create .env.example
cat > .env.example << 'EOF'
DB_USERNAME=your_username
DB_PASSWORD=your_password
DB_HOST=your-rds-endpoint.amazonaws.com
EOF

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. git add ."
echo "2. git commit -m 'Add Rails country app'"
echo "3. git push origin main"
echo "4. rails server -b \$IP -p \$PORT"
git config --global user.name 

git config --global user.email talhan0724@gmail.com

