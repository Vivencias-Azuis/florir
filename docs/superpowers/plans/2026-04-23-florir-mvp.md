# Florir MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Florir, a multi-tenant SaaS for autism clinics with scheduling, TEA medical records, and a family portal.

**Architecture:** Rails 8 JSON API (api.florir.app) with row-level multi-tenancy via `clinic_id`, backed by Turso (libSQL). Next.js 15 frontend with three entry points: landing (florir.app), clinic dashboard (web.florir.app), family portal (familia.florir.app). Jobs via Solid Queue (no Redis).

**Tech Stack:** Rails 8, Turso/libSQL, Solid Queue, Minitest, RuboCop, Brakeman — Next.js 15, TypeScript, Tailwind CSS, App Router.

**Spec:** `docs/superpowers/specs/2026-04-23-florir-design.md`

---

## Part 1 — Rails API

---

### Task 1: Bootstrap Rails API with rails-harness

**Files:**
- Create: `api/` (Rails root)
- Create: `api/Gemfile`
- Create: `api/config/database.yml`
- Create: `api/.env.example`

- [ ] **Step 1: Clone rails-harness template**

```bash
git clone https://github.com/puppe1990/rails-harness api-temp
cp -r api-temp/template/. api/
rm -rf api-temp
cd api
```

- [ ] **Step 2: Set Gemfile**

```ruby
# api/Gemfile
source "https://rubygems.org"
ruby "3.3.0"

gem "rails", "~> 8.0"
gem "libsql-activerecord", "~> 0.1"   # Turso/libSQL adapter
gem "solid_queue"
gem "bcrypt", "~> 3.1"
gem "jwt", "~> 2.8"
gem "rack-cors"
gem "dotenv-rails", groups: [:development, :test]

group :development, :test do
  gem "minitest-rails"
  gem "rubocop-rails-omakase", require: false
  gem "brakeman", require: false
end
```

- [ ] **Step 3: Set database config**

```yaml
# api/config/database.yml
default: &default
  adapter: libsql
  url: <%= ENV.fetch("DATABASE_URL", "file:dev.db") %>
  auth_token: <%= ENV["DATABASE_AUTH_TOKEN"] %>

development:
  <<: *default

test:
  <<: *default
  url: file:test.db

production:
  <<: *default
  url: <%= ENV.fetch("DATABASE_URL") %>
  auth_token: <%= ENV.fetch("DATABASE_AUTH_TOKEN") %>
```

- [ ] **Step 4: Set .env.example**

```bash
# api/.env.example
DATABASE_URL=file:dev.db
DATABASE_AUTH_TOKEN=
JWT_SECRET=replace-with-strong-secret
FRONTEND_URL=http://localhost:3000
```

- [ ] **Step 5: Install dependencies and setup**

```bash
cd api
bundle install
bin/rails db:create db:migrate
```

Expected: `Created database 'dev.db'`

- [ ] **Step 6: Commit**

```bash
git add api/
git commit -m "feat: bootstrap Rails API with rails-harness and Turso"
```

---

### Task 2: Multi-tenancy foundation — Clinic + User models

**Files:**
- Create: `api/db/migrate/*_create_clinics.rb`
- Create: `api/db/migrate/*_create_users.rb`
- Create: `api/app/models/clinic.rb`
- Create: `api/app/models/user.rb`
- Create: `api/app/models/concerns/tenant_scoped.rb`
- Create: `api/test/models/clinic_test.rb`
- Create: `api/test/models/user_test.rb`

- [ ] **Step 1: Generate migrations**

```bash
cd api
bin/rails generate migration CreateClinics name:string slug:string:uniq email:string phone:string plan:string
bin/rails generate migration CreateUsers clinic:references name:string email:string password_digest:string role:string
```

- [ ] **Step 2: Write failing model tests**

```ruby
# api/test/models/clinic_test.rb
require "test_helper"

class ClinicTest < ActiveSupport::TestCase
  test "valid with required fields" do
    clinic = Clinic.new(name: "Clínica TEA", slug: "clinica-tea", email: "admin@tea.com")
    assert clinic.valid?
  end

  test "invalid without name" do
    clinic = Clinic.new(slug: "tea", email: "x@x.com")
    assert_not clinic.valid?
    assert_includes clinic.errors[:name], "can't be blank"
  end

  test "invalid with duplicate slug" do
    Clinic.create!(name: "A", slug: "slug-a", email: "a@a.com")
    clinic = Clinic.new(name: "B", slug: "slug-a", email: "b@b.com")
    assert_not clinic.valid?
  end
end
```

```ruby
# api/test/models/user_test.rb
require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea", email: "c@c.com")
  end

  test "valid admin user" do
    user = User.new(clinic: @clinic, name: "Dra. Camila", email: "camila@tea.com",
                    password: "secret123", role: "admin")
    assert user.valid?
  end

  test "invalid with unknown role" do
    user = User.new(clinic: @clinic, name: "X", email: "x@x.com",
                    password: "secret123", role: "hacker")
    assert_not user.valid?
  end

  test "authenticate_by returns user on correct password" do
    User.create!(clinic: @clinic, name: "Dr. João", email: "joao@tea.com",
                 password: "senha123", role: "therapist")
    user = User.find_by(email: "joao@tea.com")
    assert user.authenticate("senha123")
    assert_not user.authenticate("errada")
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd api && bin/rails test test/models/clinic_test.rb test/models/user_test.rb
```

Expected: errors about missing constants/tables.

- [ ] **Step 4: Write Clinic model**

```ruby
# api/app/models/clinic.rb
class Clinic < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :patients, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, hyphens" }
  validates :email, presence: true
end
```

- [ ] **Step 5: Write TenantScoped concern**

```ruby
# api/app/models/concerns/tenant_scoped.rb
module TenantScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :clinic
    default_scope { where(clinic_id: Current.clinic_id) if Current.clinic_id }
  end
end
```

- [ ] **Step 6: Write User model**

```ruby
# api/app/models/user.rb
class User < ApplicationRecord
  include TenantScoped

  has_secure_password

  ROLES = %w[admin therapist family].freeze

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :clinic_id }
  validates :role, inclusion: { in: ROLES }

  scope :therapists, -> { where(role: %w[admin therapist]) }
end
```

- [ ] **Step 7: Create Current model**

```ruby
# api/app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :clinic_id
  attribute :user
end
```

- [ ] **Step 8: Run migrations and tests**

```bash
cd api
bin/rails db:migrate
bin/rails test test/models/clinic_test.rb test/models/user_test.rb
```

Expected: all tests PASS.

- [ ] **Step 9: Commit**

```bash
git add api/
git commit -m "feat: Clinic and User models with multi-tenancy concern"
```

---

### Task 3: Patient, TherapySession, TherapeuticGoal, GoalProgress models

**Files:**
- Create: `api/db/migrate/*_create_patients.rb`
- Create: `api/db/migrate/*_create_therapy_sessions.rb`
- Create: `api/db/migrate/*_create_therapeutic_goals.rb`
- Create: `api/db/migrate/*_create_goal_progresses.rb`
- Create: `api/app/models/patient.rb`
- Create: `api/app/models/therapy_session.rb`
- Create: `api/app/models/therapeutic_goal.rb`
- Create: `api/app/models/goal_progress.rb`
- Create: `api/test/models/patient_test.rb`
- Create: `api/test/models/therapeutic_goal_test.rb`

- [ ] **Step 1: Generate migrations**

```bash
cd api
bin/rails g migration CreatePatients clinic:references name:string birth_date:date diagnosis_date:date diagnosis_level:integer communication_method:string notes:text

bin/rails g migration CreateTherapySessions clinic:references patient:references therapist_id:integer:index scheduled_at:datetime duration_minutes:integer status:string modality:string session_notes:text

bin/rails g migration CreateTherapeuticGoals clinic:references patient:references domain:string method:string title:string description:text target:text status:string started_at:date achieved_at:date

bin/rails g migration CreateGoalProgresses goal:references session:references therapist_id:integer score:integer notes:text recorded_at:datetime
```

- [ ] **Step 2: Write failing tests**

```ruby
# api/test/models/patient_test.rb
require "test_helper"

class PatientTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-test", email: "c@c.com")
    Current.clinic_id = @clinic.id
  end

  teardown { Current.clinic_id = nil }

  test "valid patient" do
    p = Patient.new(name: "Ana Luiza", birth_date: 10.years.ago,
                    diagnosis_level: 2, communication_method: "aac")
    assert p.valid?
  end

  test "invalid without name" do
    p = Patient.new(birth_date: 5.years.ago)
    assert_not p.valid?
    assert_includes p.errors[:name], "can't be blank"
  end

  test "invalid diagnosis_level outside 1-3" do
    p = Patient.new(name: "X", birth_date: 5.years.ago, diagnosis_level: 5)
    assert_not p.valid?
  end
end
```

```ruby
# api/test/models/therapeutic_goal_test.rb
require "test_helper"

class TherapeuticGoalTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-goal", email: "g@g.com")
    Current.clinic_id = @clinic.id
    @patient = Patient.create!(name: "Pedro", birth_date: 8.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
  end

  teardown { Current.clinic_id = nil }

  test "valid goal" do
    g = TherapeuticGoal.new(patient: @patient, domain: "communication",
                             method: "pecs", title: "Usar PECS espontaneamente",
                             status: "active")
    assert g.valid?
  end

  test "invalid domain" do
    g = TherapeuticGoal.new(patient: @patient, domain: "invalid",
                             method: "aba", title: "X", status: "active")
    assert_not g.valid?
  end
end
```

- [ ] **Step 3: Run to verify failure**

```bash
cd api && bin/rails test test/models/patient_test.rb test/models/therapeutic_goal_test.rb
```

Expected: FAIL — missing tables/constants.

- [ ] **Step 4: Write models**

```ruby
# api/app/models/patient.rb
class Patient < ApplicationRecord
  include TenantScoped

  COMMUNICATION_METHODS = %w[verbal non_verbal aac].freeze
  DIAGNOSIS_LEVELS = [1, 2, 3].freeze

  has_many :therapy_sessions, dependent: :destroy
  has_many :therapeutic_goals, dependent: :destroy
  has_many :family_accesses, dependent: :destroy

  validates :name, presence: true
  validates :diagnosis_level, inclusion: { in: DIAGNOSIS_LEVELS }, allow_nil: true
  validates :communication_method, inclusion: { in: COMMUNICATION_METHODS }, allow_nil: true
end
```

```ruby
# api/app/models/therapy_session.rb
class TherapySession < ApplicationRecord
  include TenantScoped

  STATUSES = %w[scheduled confirmed completed cancelled no_show].freeze
  MODALITIES = %w[aba pecs dir_floortime speech occupational psycho other].freeze

  belongs_to :patient
  belongs_to :therapist, class_name: "User", foreign_key: :therapist_id

  validates :scheduled_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :modality, inclusion: { in: MODALITIES }, allow_nil: true
end
```

```ruby
# api/app/models/therapeutic_goal.rb
class TherapeuticGoal < ApplicationRecord
  include TenantScoped

  DOMAINS = %w[communication social_skills behavior motor daily_living cognitive].freeze
  METHODS = %w[aba pecs dir_floortime vb_mapp other].freeze
  STATUSES = %w[active achieved paused discontinued].freeze

  belongs_to :patient
  has_many :goal_progresses, foreign_key: :goal_id, dependent: :destroy

  validates :title, presence: true
  validates :domain, inclusion: { in: DOMAINS }
  validates :method, inclusion: { in: METHODS }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }
end
```

```ruby
# api/app/models/goal_progress.rb
class GoalProgress < ApplicationRecord
  belongs_to :goal, class_name: "TherapeuticGoal"
  belongs_to :session, class_name: "TherapySession"
  belongs_to :therapist, class_name: "User", foreign_key: :therapist_id

  validates :score, numericality: { in: 0..100 }
  validates :recorded_at, presence: true
end
```

- [ ] **Step 5: Migrate and run tests**

```bash
cd api && bin/rails db:migrate
bin/rails test test/models/patient_test.rb test/models/therapeutic_goal_test.rb
```

Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add api/
git commit -m "feat: Patient, TherapySession, TherapeuticGoal, GoalProgress models"
```

---

### Task 4: FamilyAccess and Message models

**Files:**
- Create: `api/db/migrate/*_create_family_accesses.rb`
- Create: `api/db/migrate/*_create_messages.rb`
- Create: `api/app/models/family_access.rb`
- Create: `api/app/models/message.rb`
- Create: `api/test/models/family_access_test.rb`

- [ ] **Step 1: Generate migrations**

```bash
cd api
bin/rails g migration CreateFamilyAccesses patient:references user:references relation:string access_token:string:uniq active:boolean

bin/rails g migration CreateMessages clinic:references patient:references sender_id:integer receiver_id:integer body:text read_at:datetime
```

- [ ] **Step 2: Write failing test**

```ruby
# api/test/models/family_access_test.rb
require "test_helper"

class FamilyAccessTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-fam", email: "f@f.com")
    Current.clinic_id = @clinic.id
    @patient = Patient.create!(name: "Ana", birth_date: 7.years.ago,
                                diagnosis_level: 2, communication_method: "aac")
    @user = User.create!(clinic: @clinic, name: "Mãe Ana", email: "mae@email.com",
                         password: "senha123", role: "family")
  end

  teardown { Current.clinic_id = nil }

  test "generates access_token on create" do
    fa = FamilyAccess.create!(patient: @patient, user: @user,
                               relation: "mother", active: true)
    assert_not_nil fa.access_token
    assert fa.access_token.length >= 32
  end

  test "invalid relation" do
    fa = FamilyAccess.new(patient: @patient, user: @user,
                          relation: "alien", active: true)
    assert_not fa.valid?
  end
end
```

- [ ] **Step 3: Run to verify failure**

```bash
cd api && bin/rails test test/models/family_access_test.rb
```

Expected: FAIL.

- [ ] **Step 4: Write models**

```ruby
# api/app/models/family_access.rb
class FamilyAccess < ApplicationRecord
  RELATIONS = %w[mother father guardian other].freeze

  belongs_to :patient
  belongs_to :user

  before_create :generate_token

  validates :relation, inclusion: { in: RELATIONS }
  validates :access_token, uniqueness: true

  private

  def generate_token
    self.access_token = SecureRandom.hex(24)
  end
end
```

```ruby
# api/app/models/message.rb
class Message < ApplicationRecord
  include TenantScoped

  belongs_to :patient
  belongs_to :sender, class_name: "User", foreign_key: :sender_id
  belongs_to :receiver, class_name: "User", foreign_key: :receiver_id

  validates :body, presence: true
end
```

- [ ] **Step 5: Migrate and run tests**

```bash
cd api && bin/rails db:migrate
bin/rails test test/models/family_access_test.rb
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add api/
git commit -m "feat: FamilyAccess with auto token generation and Message models"
```

---

### Task 5: JWT Auth — login, register, tenant scoping

**Files:**
- Create: `api/app/controllers/application_controller.rb`
- Create: `api/app/controllers/auth_controller.rb`
- Create: `api/app/services/token_service.rb`
- Create: `api/config/routes.rb`
- Create: `api/test/controllers/auth_controller_test.rb`

- [ ] **Step 1: Write failing request test**

```ruby
# api/test/controllers/auth_controller_test.rb
require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-auth", email: "auth@tea.com")
    Current.clinic_id = @clinic.id
    @user = User.create!(clinic: @clinic, name: "Dra. Camila", email: "camila@tea.com",
                         password: "senha123", role: "admin")
    Current.clinic_id = nil
  end

  test "register creates clinic and admin user" do
    post "/auth/register", params: {
      clinic: { name: "Nova Clínica", slug: "nova-clinica", email: "nova@tea.com" },
      user: { name: "Admin", email: "admin@nova.com", password: "senha456" }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert_equal "admin", json["user"]["role"]
  end

  test "login returns token on valid credentials" do
    post "/auth/login", params: { email: "camila@tea.com", password: "senha123",
                                   clinic_slug: "tea-auth" }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["token"].present?
  end

  test "login returns 401 on wrong password" do
    post "/auth/login", params: { email: "camila@tea.com", password: "errada",
                                   clinic_slug: "tea-auth" }, as: :json
    assert_response :unauthorized
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
cd api && bin/rails test test/controllers/auth_controller_test.rb
```

Expected: routing errors.

- [ ] **Step 3: Write TokenService**

```ruby
# api/app/services/token_service.rb
class TokenService
  SECRET = ENV.fetch("JWT_SECRET", "dev-secret-change-in-production")
  EXPIRY = 24.hours

  def self.encode(payload)
    payload[:exp] = EXPIRY.from_now.to_i
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.decode(token)
    JWT.decode(token, SECRET, true, algorithm: "HS256").first.with_indifferent_access
  rescue JWT::DecodeError
    nil
  end
end
```

- [ ] **Step 4: Write ApplicationController**

```ruby
# api/app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = TokenService.decode(token)
    render json: { error: "Unauthorized" }, status: :unauthorized and return unless payload

    Current.clinic_id = payload[:clinic_id]
    Current.user = User.find_by(id: payload[:user_id])
    render json: { error: "Unauthorized" }, status: :unauthorized unless Current.user
  end

  def current_user
    Current.user
  end
end
```

- [ ] **Step 5: Write AuthController**

```ruby
# api/app/controllers/auth_controller.rb
class AuthController < ApplicationController
  skip_before_action :authenticate!, only: %i[login register]

  def login
    clinic = Clinic.find_by(slug: params[:clinic_slug])
    user = clinic&.users&.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = TokenService.encode(user_id: user.id, clinic_id: clinic.id, role: user.role)
      render json: { token: token, user: user_json(user) }
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def register
    clinic = Clinic.new(params.require(:clinic).permit(:name, :slug, :email, :phone))
    user_params = params.require(:user).permit(:name, :email, :password)

    ActiveRecord::Base.transaction do
      clinic.save!
      user = clinic.users.create!(user_params.merge(role: "admin"))
      token = TokenService.encode(user_id: user.id, clinic_id: clinic.id, role: "admin")
      render json: { token: token, user: user_json(user) }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def user_json(user)
    { id: user.id, name: user.name, email: user.email, role: user.role }
  end
end
```

- [ ] **Step 6: Add routes**

```ruby
# api/config/routes.rb
Rails.application.routes.draw do
  post "/auth/login",    to: "auth#login"
  post "/auth/register", to: "auth#register"

  resources :patients do
    resources :sessions, only: %i[index], controller: "therapy_sessions"
    resources :goals, only: %i[index], controller: "therapeutic_goals"
    resources :family_accesses, only: %i[index create destroy]
  end

  resources :therapy_sessions, only: %i[show create update destroy]
  resources :therapeutic_goals, only: %i[show create update destroy] do
    resources :progresses, only: %i[index create], controller: "goal_progresses"
  end

  resources :messages, only: %i[index create] do
    member { put :read }
  end

  namespace :family do
    get "/:token/dashboard", to: "portal#dashboard"
    get "/:token/sessions",  to: "portal#sessions"
    get "/:token/goals",     to: "portal#goals"
    post "/:token/messages", to: "portal#create_message"
    get "/:token/messages",  to: "portal#messages"
  end
end
```

- [ ] **Step 7: Run tests**

```bash
cd api && bin/rails test test/controllers/auth_controller_test.rb
```

Expected: all PASS.

- [ ] **Step 8: Commit**

```bash
git add api/
git commit -m "feat: JWT auth with login, register, and tenant scoping"
```

---

### Task 6: Patients API

**Files:**
- Create: `api/app/controllers/patients_controller.rb`
- Create: `api/test/controllers/patients_controller_test.rb`

- [ ] **Step 1: Write failing test**

```ruby
# api/test/controllers/patients_controller_test.rb
require "test_helper"

class PatientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-pat", email: "pat@tea.com")
    Current.clinic_id = @clinic.id
    @admin = User.create!(clinic: @clinic, name: "Admin", email: "admin@tea.com",
                          password: "senha123", role: "admin")
    @token = TokenService.encode(user_id: @admin.id, clinic_id: @clinic.id, role: "admin")
    @patient = Patient.create!(name: "Ana Luiza", birth_date: 7.years.ago,
                                diagnosis_level: 2, communication_method: "aac")
    Current.clinic_id = nil
  end

  test "index returns patients for clinic" do
    get "/patients", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal "Ana Luiza", json.first["name"]
  end

  test "show returns single patient" do
    get "/patients/#{@patient.id}", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    assert_equal "Ana Luiza", JSON.parse(response.body)["name"]
  end

  test "create adds patient" do
    post "/patients", headers: { "Authorization" => "Bearer #{@token}" },
         params: { name: "Pedro", birth_date: "2018-03-10",
                   diagnosis_level: 1, communication_method: "verbal" }, as: :json
    assert_response :created
  end

  test "cannot access patients from another clinic" do
    other_clinic = Clinic.create!(name: "Outra", slug: "outra", email: "o@o.com")
    Current.clinic_id = other_clinic.id
    other_patient = Patient.create!(name: "Intruso", birth_date: 5.years.ago, diagnosis_level: 1)
    Current.clinic_id = nil

    get "/patients/#{other_patient.id}", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :not_found
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
cd api && bin/rails test test/controllers/patients_controller_test.rb
```

Expected: routing/controller errors.

- [ ] **Step 3: Write controller**

```ruby
# api/app/controllers/patients_controller.rb
class PatientsController < ApplicationController
  before_action :set_patient, only: %i[show update destroy]

  def index
    render json: Patient.all.map { |p| patient_json(p) }
  end

  def show
    render json: patient_json(@patient)
  end

  def create
    patient = Patient.new(patient_params)
    if patient.save
      render json: patient_json(patient), status: :created
    else
      render json: { errors: patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @patient.update(patient_params)
      render json: patient_json(@patient)
    else
      render json: { errors: @patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @patient.destroy
    head :no_content
  end

  private

  def set_patient
    @patient = Patient.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def patient_params
    params.permit(:name, :birth_date, :diagnosis_date, :diagnosis_level,
                  :communication_method, :notes)
  end

  def patient_json(p)
    p.slice(:id, :name, :birth_date, :diagnosis_date, :diagnosis_level,
            :communication_method, :notes, :created_at)
  end
end
```

- [ ] **Step 4: Run tests**

```bash
cd api && bin/rails test test/controllers/patients_controller_test.rb
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add api/
git commit -m "feat: Patients API with tenant isolation"
```

---

### Task 7: TherapySessions API

**Files:**
- Create: `api/app/controllers/therapy_sessions_controller.rb`
- Create: `api/test/controllers/therapy_sessions_controller_test.rb`

- [ ] **Step 1: Write failing test**

```ruby
# api/test/controllers/therapy_sessions_controller_test.rb
require "test_helper"

class TherapySessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-sess", email: "sess@tea.com")
    Current.clinic_id = @clinic.id
    @therapist = User.create!(clinic: @clinic, name: "Dra. Ana", email: "ana@tea.com",
                               password: "senha123", role: "therapist")
    @patient = Patient.create!(name: "Pedro", birth_date: 8.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
    @token = TokenService.encode(user_id: @therapist.id, clinic_id: @clinic.id, role: "therapist")
    Current.clinic_id = nil
  end

  test "create schedules session" do
    post "/therapy_sessions", headers: { "Authorization" => "Bearer #{@token}" },
         params: { patient_id: @patient.id, therapist_id: @therapist.id,
                   scheduled_at: 1.day.from_now.iso8601,
                   duration_minutes: 60, status: "scheduled", modality: "aba" }, as: :json
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "scheduled", json["status"]
  end

  test "index returns sessions for patient" do
    Current.clinic_id = @clinic.id
    TherapySession.create!(patient: @patient, therapist_id: @therapist.id,
                            scheduled_at: 1.day.from_now, duration_minutes: 60,
                            status: "scheduled", modality: "aba")
    Current.clinic_id = nil

    get "/patients/#{@patient.id}/sessions", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    assert_equal 1, JSON.parse(response.body).length
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
cd api && bin/rails test test/controllers/therapy_sessions_controller_test.rb
```

- [ ] **Step 3: Write controller**

```ruby
# api/app/controllers/therapy_sessions_controller.rb
class TherapySessionsController < ApplicationController
  before_action :set_session, only: %i[show update destroy]

  def index
    sessions = if params[:patient_id]
                 Patient.find(params[:patient_id]).therapy_sessions.order(scheduled_at: :asc)
               else
                 TherapySession.all.order(scheduled_at: :asc)
               end
    render json: sessions.map { |s| session_json(s) }
  end

  def create
    session = TherapySession.new(session_params)
    if session.save
      render json: session_json(session), status: :created
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @session.update(session_params)
      render json: session_json(@session)
    else
      render json: { errors: @session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @session.destroy
    head :no_content
  end

  private

  def set_session
    @session = TherapySession.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def session_params
    params.permit(:patient_id, :therapist_id, :scheduled_at, :duration_minutes,
                  :status, :modality, :session_notes)
  end

  def session_json(s)
    s.slice(:id, :patient_id, :therapist_id, :scheduled_at, :duration_minutes,
            :status, :modality, :session_notes)
  end
end
```

- [ ] **Step 4: Run tests**

```bash
cd api && bin/rails test test/controllers/therapy_sessions_controller_test.rb
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add api/
git commit -m "feat: TherapySessions API"
```

---

### Task 8: TherapeuticGoals + GoalProgresses API

**Files:**
- Create: `api/app/controllers/therapeutic_goals_controller.rb`
- Create: `api/app/controllers/goal_progresses_controller.rb`
- Create: `api/test/controllers/therapeutic_goals_controller_test.rb`

- [ ] **Step 1: Write failing test**

```ruby
# api/test/controllers/therapeutic_goals_controller_test.rb
require "test_helper"

class TherapeuticGoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-goals", email: "goal@tea.com")
    Current.clinic_id = @clinic.id
    @therapist = User.create!(clinic: @clinic, name: "Dra. Julia", email: "julia@tea.com",
                               password: "senha123", role: "therapist")
    @patient = Patient.create!(name: "Bia", birth_date: 6.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
    @token = TokenService.encode(user_id: @therapist.id, clinic_id: @clinic.id, role: "therapist")
    Current.clinic_id = nil
  end

  test "create goal" do
    post "/therapeutic_goals", headers: { "Authorization" => "Bearer #{@token}" },
         params: { patient_id: @patient.id, domain: "communication",
                   method: "pecs", title: "Usar PECS espontaneamente",
                   status: "active" }, as: :json
    assert_response :created
    assert_equal "communication", JSON.parse(response.body)["domain"]
  end

  test "create progress for goal" do
    Current.clinic_id = @clinic.id
    session = TherapySession.create!(patient: @patient, therapist_id: @therapist.id,
                                      scheduled_at: 1.day.ago, duration_minutes: 60,
                                      status: "completed", modality: "pecs")
    goal = TherapeuticGoal.create!(patient: @patient, domain: "communication",
                                    method: "pecs", title: "PECS", status: "active")
    Current.clinic_id = nil

    post "/therapeutic_goals/#{goal.id}/progresses",
         headers: { "Authorization" => "Bearer #{@token}" },
         params: { session_id: session.id, therapist_id: @therapist.id,
                   score: 75, recorded_at: Time.current.iso8601 }, as: :json
    assert_response :created
    assert_equal 75, JSON.parse(response.body)["score"]
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
cd api && bin/rails test test/controllers/therapeutic_goals_controller_test.rb
```

- [ ] **Step 3: Write controllers**

```ruby
# api/app/controllers/therapeutic_goals_controller.rb
class TherapeuticGoalsController < ApplicationController
  before_action :set_goal, only: %i[show update destroy]

  def index
    goals = Patient.find(params[:patient_id]).therapeutic_goals.order(created_at: :desc)
    render json: goals.map { |g| goal_json(g) }
  end

  def show
    render json: goal_json(@goal)
  end

  def create
    goal = TherapeuticGoal.new(goal_params)
    if goal.save
      render json: goal_json(goal), status: :created
    else
      render json: { errors: goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @goal.update(goal_params)
      render json: goal_json(@goal)
    else
      render json: { errors: @goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    head :no_content
  end

  private

  def set_goal
    @goal = TherapeuticGoal.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def goal_params
    params.permit(:patient_id, :domain, :method, :title, :description,
                  :target, :status, :started_at, :achieved_at)
  end

  def goal_json(g)
    g.slice(:id, :patient_id, :domain, :method, :title, :description,
            :target, :status, :started_at, :achieved_at)
  end
end
```

```ruby
# api/app/controllers/goal_progresses_controller.rb
class GoalProgressesController < ApplicationController
  def index
    goal = TherapeuticGoal.find(params[:therapeutic_goal_id])
    render json: goal.goal_progresses.order(recorded_at: :asc).map { |p| progress_json(p) }
  end

  def create
    goal = TherapeuticGoal.find(params[:therapeutic_goal_id])
    progress = goal.goal_progresses.new(progress_params)
    if progress.save
      render json: progress_json(progress), status: :created
    else
      render json: { errors: progress.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def progress_params
    params.permit(:session_id, :therapist_id, :score, :notes, :recorded_at)
  end

  def progress_json(p)
    p.slice(:id, :goal_id, :session_id, :therapist_id, :score, :notes, :recorded_at)
  end
end
```

- [ ] **Step 4: Run tests**

```bash
cd api && bin/rails test test/controllers/therapeutic_goals_controller_test.rb
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add api/
git commit -m "feat: TherapeuticGoals and GoalProgresses API"
```

---

### Task 9: Family Portal API + Messages

**Files:**
- Create: `api/app/controllers/family/portal_controller.rb`
- Create: `api/app/controllers/messages_controller.rb`
- Create: `api/test/controllers/family_portal_controller_test.rb`

- [ ] **Step 1: Write failing test**

```ruby
# api/test/controllers/family_portal_controller_test.rb
require "test_helper"

class FamilyPortalControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-portal", email: "portal@tea.com")
    Current.clinic_id = @clinic.id
    @family_user = User.create!(clinic: @clinic, name: "Mãe", email: "mae@email.com",
                                 password: "senha123", role: "family")
    @patient = Patient.create!(name: "Ana", birth_date: 7.years.ago,
                                diagnosis_level: 2, communication_method: "aac")
    @access = FamilyAccess.create!(patient: @patient, user: @family_user,
                                    relation: "mother", active: true)
    Current.clinic_id = nil
  end

  test "dashboard returns patient info and goals" do
    get "/family/#{@access.access_token}/dashboard"
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Ana", json["patient"]["name"]
    assert json.key?("goals")
  end

  test "invalid token returns 404" do
    get "/family/invalid-token/dashboard"
    assert_response :not_found
  end
end
```

- [ ] **Step 2: Run to verify failure**

```bash
cd api && bin/rails test test/controllers/family_portal_controller_test.rb
```

- [ ] **Step 3: Write controllers**

```ruby
# api/app/controllers/family/portal_controller.rb
module Family
  class PortalController < ApplicationController
    skip_before_action :authenticate!
    before_action :set_access

    def dashboard
      render json: {
        patient: patient_json(@patient),
        goals: @patient.therapeutic_goals.where(status: "active").map { |g| goal_summary(g) },
        next_session: next_session_json
      }
    end

    def sessions
      sessions = @patient.therapy_sessions
                         .where(scheduled_at: Time.current..)
                         .order(scheduled_at: :asc)
                         .limit(10)
      render json: sessions.map { |s| { id: s.id, scheduled_at: s.scheduled_at,
                                         duration_minutes: s.duration_minutes,
                                         status: s.status, modality: s.modality } }
    end

    def goals
      render json: @patient.therapeutic_goals.where(status: "active").map { |g| goal_summary(g) }
    end

    def messages
      msgs = Message.where(patient_id: @patient.id).order(created_at: :asc)
      render json: msgs.map { |m| { id: m.id, body: m.body, sender_id: m.sender_id,
                                     read_at: m.read_at, created_at: m.created_at } }
    end

    def create_message
      msg = Message.new(
        clinic_id: @patient.clinic_id,
        patient_id: @patient.id,
        sender_id: @access.user_id,
        body: params[:body]
      )
      if msg.save
        render json: { id: msg.id, body: msg.body }, status: :created
      else
        render json: { errors: msg.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_access
      @access = FamilyAccess.find_by(access_token: params[:token], active: true)
      render json: { error: "Not found" }, status: :not_found and return unless @access
      @patient = @access.patient
      Current.clinic_id = @patient.clinic_id
    end

    def patient_json(p)
      p.slice(:id, :name, :birth_date, :diagnosis_level, :communication_method)
    end

    def goal_summary(g)
      last = g.goal_progresses.order(recorded_at: :desc).first
      g.slice(:id, :title, :domain, :method, :status).merge(last_score: last&.score)
    end

    def next_session_json
      s = @patient.therapy_sessions.where(scheduled_at: Time.current..)
                  .order(scheduled_at: :asc).first
      return nil unless s
      { scheduled_at: s.scheduled_at, modality: s.modality, status: s.status }
    end
  end
end
```

```ruby
# api/app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def index
    msgs = Message.where(patient_id: params[:patient_id]).order(created_at: :asc)
    render json: msgs.map { |m| m.slice(:id, :body, :sender_id, :receiver_id, :read_at, :created_at) }
  end

  def create
    msg = Message.new(message_params)
    if msg.save
      render json: msg.slice(:id, :body), status: :created
    else
      render json: { errors: msg.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def read
    msg = Message.find(params[:id])
    msg.update!(read_at: Time.current)
    head :ok
  end

  private

  def message_params
    params.permit(:patient_id, :receiver_id, :body).merge(
      clinic_id: Current.clinic_id,
      sender_id: current_user.id
    )
  end
end
```

- [ ] **Step 4: Run tests**

```bash
cd api && bin/rails test test/controllers/family_portal_controller_test.rb
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add api/
git commit -m "feat: Family portal API and Messages controller"
```

---

### Task 10: Solid Queue jobs — magic link and session reminders

**Files:**
- Create: `api/app/jobs/family_magic_link_job.rb`
- Create: `api/app/jobs/session_reminder_job.rb`
- Create: `api/app/mailers/florir_mailer.rb`
- Create: `api/app/views/florir_mailer/magic_link.html.erb`
- Create: `api/app/views/florir_mailer/session_reminder.html.erb`
- Create: `api/test/jobs/family_magic_link_job_test.rb`

- [ ] **Step 1: Configure Solid Queue**

```ruby
# api/config/application.rb (add inside class Application)
config.active_job.queue_adapter = :solid_queue
```

```bash
cd api && bin/rails solid_queue:install
bin/rails db:migrate
```

- [ ] **Step 2: Write failing test**

```ruby
# api/test/jobs/family_magic_link_job_test.rb
require "test_helper"

class FamilyMagicLinkJobTest < ActiveJob::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-job", email: "job@tea.com")
    Current.clinic_id = @clinic.id
    @user = User.create!(clinic: @clinic, name: "Mãe", email: "mae@job.com",
                         password: "senha123", role: "family")
    @patient = Patient.create!(name: "Filho", birth_date: 5.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
    @access = FamilyAccess.create!(patient: @patient, user: @user,
                                    relation: "mother", active: true)
    Current.clinic_id = nil
  end

  test "enqueues magic link email" do
    assert_enqueued_with(job: FamilyMagicLinkJob) do
      FamilyMagicLinkJob.perform_later(@access.id)
    end
  end

  test "performs without error" do
    assert_nothing_raised { FamilyMagicLinkJob.perform_now(@access.id) }
  end
end
```

- [ ] **Step 3: Run to verify failure**

```bash
cd api && bin/rails test test/jobs/family_magic_link_job_test.rb
```

- [ ] **Step 4: Write mailer**

```ruby
# api/app/mailers/florir_mailer.rb
class FlorirMailer < ApplicationMailer
  default from: "noreply@florir.app"

  def magic_link(family_access)
    @access = family_access
    @patient = family_access.patient
    @url = "#{ENV.fetch("FRONTEND_URL", "http://localhost:3001")}/familia/#{@access.access_token}/progresso"
    mail(to: family_access.user.email,
         subject: "Acesse o progresso de #{@patient.name} — Florir")
  end

  def session_reminder(session)
    @session = session
    @patient = session.patient
    family_emails = @patient.family_accesses.where(active: true).includes(:user).map { |fa| fa.user.email }
    mail(to: family_emails,
         subject: "Lembrete: sessão de #{@patient.name} amanhã — Florir")
  end
end
```

- [ ] **Step 5: Write email templates**

```erb
<%# api/app/views/florir_mailer/magic_link.html.erb %>
<h2>Olá!</h2>
<p>Você foi convidado(a) para acompanhar o progresso de <strong><%= @patient.name %></strong> no Florir.</p>
<p><a href="<%= @url %>">Clique aqui para acessar</a></p>
<p>Este link é pessoal e não expira.</p>
```

```erb
<%# api/app/views/florir_mailer/session_reminder.html.erb %>
<h2>Lembrete de sessão</h2>
<p><strong><%= @patient.name %></strong> tem sessão de <%= @session.modality.upcase %> amanhã às <%= @session.scheduled_at.strftime("%H:%M") %>.</p>
```

- [ ] **Step 6: Write jobs**

```ruby
# api/app/jobs/family_magic_link_job.rb
class FamilyMagicLinkJob < ApplicationJob
  queue_as :default

  def perform(family_access_id)
    access = FamilyAccess.find(family_access_id)
    FlorirMailer.magic_link(access).deliver_now
  end
end
```

```ruby
# api/app/jobs/session_reminder_job.rb
class SessionReminderJob < ApplicationJob
  queue_as :default

  def perform(session_id)
    session = TherapySession.find(session_id)
    FlorirMailer.session_reminder(session).deliver_now
  end
end
```

- [ ] **Step 7: Trigger job on FamilyAccess creation**

```ruby
# api/app/models/family_access.rb — add after_create callback
after_create :send_magic_link

private

def send_magic_link
  FamilyMagicLinkJob.perform_later(id)
end
```

- [ ] **Step 8: Run tests**

```bash
cd api && bin/rails test test/jobs/family_magic_link_job_test.rb
```

Expected: PASS.

- [ ] **Step 9: Run full test suite**

```bash
cd api && bin/rails test
```

Expected: all PASS.

- [ ] **Step 10: Commit**

```bash
git add api/
git commit -m "feat: Solid Queue jobs for magic link and session reminders"
```

---

### Task 11: CORS, security headers, Brakeman

**Files:**
- Modify: `api/config/initializers/cors.rb`
- Modify: `api/Gemfile`

- [ ] **Step 1: Configure CORS**

```ruby
# api/config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_URL", "http://localhost:3000"),
            /\Ahttps:\/\/.*\.florir\.app\z/
    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: ["Authorization"]
  end
end
```

- [ ] **Step 2: Run Brakeman security audit**

```bash
cd api && bundle exec brakeman --no-pager
```

Expected: no high-severity warnings.

- [ ] **Step 3: Run RuboCop**

```bash
cd api && bundle exec rubocop --autocorrect-all
```

- [ ] **Step 4: Commit**

```bash
git add api/
git commit -m "chore: CORS config, Brakeman clean, RuboCop pass"
```

---

## Part 2 — Next.js Frontend

---

### Task 12: Bootstrap Next.js with Tailwind and API client

**Files:**
- Create: `web/` (Next.js root)
- Create: `web/src/lib/api.ts`
- Create: `web/src/lib/auth.ts`
- Create: `web/.env.local`

- [ ] **Step 1: Create Next.js app**

```bash
npx create-next-app@latest web \
  --typescript --tailwind --app --src-dir \
  --no-eslint --import-alias "@/*"
```

- [ ] **Step 2: Set env**

```bash
# web/.env.local
NEXT_PUBLIC_API_URL=http://localhost:4000
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

- [ ] **Step 3: Write API client**

```typescript
// web/src/lib/api.ts
const API_URL = process.env.NEXT_PUBLIC_API_URL!

async function request<T>(
  path: string,
  options: RequestInit = {},
  token?: string
): Promise<T> {
  const headers: HeadersInit = {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  }

  const res = await fetch(`${API_URL}${path}`, { ...options, headers })

  if (!res.ok) {
    const error = await res.json().catch(() => ({ error: res.statusText }))
    throw new Error(error.error || "Request failed")
  }

  if (res.status === 204) return undefined as T
  return res.json()
}

export const api = {
  get: <T>(path: string, token?: string) =>
    request<T>(path, { method: "GET" }, token),

  post: <T>(path: string, body: unknown, token?: string) =>
    request<T>(path, { method: "POST", body: JSON.stringify(body) }, token),

  put: <T>(path: string, body: unknown, token?: string) =>
    request<T>(path, { method: "PUT", body: JSON.stringify(body) }, token),

  delete: <T>(path: string, token?: string) =>
    request<T>(path, { method: "DELETE" }, token),
}
```

- [ ] **Step 4: Write auth helpers**

```typescript
// web/src/lib/auth.ts
export function getToken(): string | null {
  if (typeof window === "undefined") return null
  return localStorage.getItem("florir_token")
}

export function setToken(token: string): void {
  localStorage.setItem("florir_token", token)
}

export function clearToken(): void {
  localStorage.removeItem("florir_token")
}

export function parseToken(token: string): { role: string; clinic_id: number; user_id: number } | null {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]))
    return payload
  } catch {
    return null
  }
}
```

- [ ] **Step 5: Verify dev server starts**

```bash
cd web && npm run dev
```

Expected: `http://localhost:3000` accessible.

- [ ] **Step 6: Commit**

```bash
git add web/
git commit -m "feat: bootstrap Next.js with API client and auth helpers"
```

---

### Task 13: Login page

**Files:**
- Create: `web/src/app/login/page.tsx`
- Create: `web/src/app/login/actions.ts`
- Create: `web/src/components/ui/Button.tsx`
- Create: `web/src/components/ui/Input.tsx`

- [ ] **Step 1: Write shared UI components**

```typescript
// web/src/components/ui/Button.tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "ghost"
  loading?: boolean
}

export function Button({ children, variant = "primary", loading, className = "", ...props }: ButtonProps) {
  const base = "inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50"
  const variants = {
    primary: "bg-blue-600 text-white hover:bg-blue-700",
    ghost: "bg-transparent text-slate-600 hover:bg-slate-100",
  }
  return (
    <button className={`${base} ${variants[variant]} ${className}`} disabled={loading || props.disabled} {...props}>
      {loading ? "Carregando..." : children}
    </button>
  )
}
```

```typescript
// web/src/components/ui/Input.tsx
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string
  error?: string
}

export function Input({ label, error, className = "", ...props }: InputProps) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-sm font-medium text-slate-700">{label}</label>
      <input
        className={`rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 ${error ? "border-red-400" : ""} ${className}`}
        {...props}
      />
      {error && <span className="text-xs text-red-500">{error}</span>}
    </div>
  )
}
```

- [ ] **Step 2: Write login action**

```typescript
// web/src/app/login/actions.ts
"use server"
import { redirect } from "next/navigation"
import { api } from "@/lib/api"
import { cookies } from "next/headers"

export async function loginAction(formData: FormData) {
  const email = formData.get("email") as string
  const password = formData.get("password") as string
  const clinic_slug = formData.get("clinic_slug") as string

  try {
    const data = await api.post<{ token: string }>("/auth/login", { email, password, clinic_slug })
    const cookieStore = await cookies()
    cookieStore.set("florir_token", data.token, { httpOnly: true, path: "/" })
  } catch {
    return { error: "Email, senha ou código da clínica inválidos" }
  }

  redirect("/dashboard")
}
```

- [ ] **Step 3: Write login page**

```typescript
// web/src/app/login/page.tsx
import { loginAction } from "./actions"
import { Input } from "@/components/ui/Input"
import { Button } from "@/components/ui/Button"

export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50">
      <div className="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold text-slate-900">Florir</h1>
          <p className="mt-1 text-sm text-slate-500">Acesse sua clínica</p>
        </div>
        <form action={loginAction} className="flex flex-col gap-4">
          <Input label="Código da clínica" name="clinic_slug" placeholder="minha-clinica" required />
          <Input label="E-mail" name="email" type="email" placeholder="voce@clinica.com" required />
          <Input label="Senha" name="password" type="password" placeholder="••••••••" required />
          <Button type="submit" className="mt-2 w-full">Entrar</Button>
        </form>
      </div>
    </main>
  )
}
```

- [ ] **Step 4: Verify in browser**

```bash
cd web && npm run dev
```

Open `http://localhost:3000/login`. Verify form renders with Calmo & Clínico style.

- [ ] **Step 5: Commit**

```bash
git add web/
git commit -m "feat: login page with server action"
```

---

### Task 14: Dashboard layout with sidebar

**Files:**
- Create: `web/src/app/(clinic)/layout.tsx`
- Create: `web/src/app/(clinic)/dashboard/page.tsx`
- Create: `web/src/components/layout/Sidebar.tsx`
- Create: `web/src/components/layout/TopBar.tsx`

- [ ] **Step 1: Write Sidebar**

```typescript
// web/src/components/layout/Sidebar.tsx
"use client"
import Link from "next/link"
import { usePathname } from "next/navigation"

const NAV = [
  { href: "/dashboard", label: "Dashboard", icon: "⊡" },
  { href: "/agenda", label: "Agenda", icon: "📅" },
  { href: "/pacientes", label: "Pacientes", icon: "👤" },
  { href: "/configuracoes", label: "Config", icon: "⚙" },
]

export function Sidebar() {
  const pathname = usePathname()
  return (
    <aside className="flex h-screen w-14 flex-col items-center bg-slate-900 py-4 gap-4">
      <div className="mb-2 flex h-8 w-8 items-center justify-center rounded-lg bg-blue-600 text-white text-xs font-bold">F</div>
      {NAV.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          title={item.label}
          className={`flex h-9 w-9 items-center justify-center rounded-lg text-lg transition-colors ${
            pathname.startsWith(item.href)
              ? "bg-blue-600 text-white"
              : "text-slate-400 hover:bg-slate-700 hover:text-white"
          }`}
        >
          {item.icon}
        </Link>
      ))}
    </aside>
  )
}
```

- [ ] **Step 2: Write clinic layout**

```typescript
// web/src/app/(clinic)/layout.tsx
import { Sidebar } from "@/components/layout/Sidebar"

export default function ClinicLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 overflow-y-auto">{children}</main>
    </div>
  )
}
```

- [ ] **Step 3: Write Dashboard page**

```typescript
// web/src/app/(clinic)/dashboard/page.tsx
import { cookies } from "next/headers"
import { api } from "@/lib/api"

interface Patient { id: number; name: string }
interface Session { id: number; scheduled_at: string; status: string; modality: string }

async function getDashboardData(token: string) {
  const [patients, sessions] = await Promise.all([
    api.get<Patient[]>("/patients", token),
    api.get<Session[]>("/therapy_sessions?today=true", token),
  ])
  return { patients, sessions }
}

export default async function DashboardPage() {
  const cookieStore = await cookies()
  const token = cookieStore.get("florir_token")?.value ?? ""
  const { patients, sessions } = await getDashboardData(token)

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-xl font-bold text-slate-900">Dashboard</h1>
        <p className="text-sm text-slate-500">Visão geral da clínica</p>
      </div>

      <div className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
        {[
          { label: "Pacientes ativos", value: patients.length, color: "text-slate-900" },
          { label: "Sessões hoje", value: sessions.length, color: "text-blue-600" },
          { label: "Objetivos ativos", value: "—", color: "text-slate-900" },
          { label: "Mensagens", value: "—", color: "text-amber-500" },
        ].map((stat) => (
          <div key={stat.label} className="rounded-xl border border-slate-200 bg-white p-4">
            <p className="text-xs text-slate-400">{stat.label}</p>
            <p className={`mt-1 text-2xl font-bold ${stat.color}`}>{stat.value}</p>
          </div>
        ))}
      </div>

      <div className="rounded-xl border border-slate-200 bg-white p-4">
        <h2 className="mb-3 text-sm font-semibold text-slate-600">Agenda de hoje</h2>
        {sessions.length === 0 ? (
          <p className="text-sm text-slate-400">Nenhuma sessão hoje.</p>
        ) : (
          <div className="flex flex-col gap-2">
            {sessions.map((s) => (
              <div key={s.id} className="flex items-center gap-3 rounded-lg bg-blue-50 px-3 py-2 border-l-4 border-blue-500">
                <span className="text-xs text-slate-500 w-10">
                  {new Date(s.scheduled_at).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}
                </span>
                <span className="flex-1 text-sm font-medium text-blue-900">{s.modality.toUpperCase()}</span>
                <span className="rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-700">{s.status}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Verify in browser**

Open `http://localhost:3000/dashboard`. Confirm sidebar renders, metrics show.

- [ ] **Step 5: Commit**

```bash
git add web/
git commit -m "feat: dashboard layout with sidebar and metrics"
```

---

### Task 15: Patients list + Prontuário page

**Files:**
- Create: `web/src/app/(clinic)/pacientes/page.tsx`
- Create: `web/src/app/(clinic)/pacientes/[id]/page.tsx`
- Create: `web/src/components/patients/PatientCard.tsx`
- Create: `web/src/components/patients/GoalProgressBar.tsx`

- [ ] **Step 1: Write PatientCard**

```typescript
// web/src/components/patients/PatientCard.tsx
import Link from "next/link"

interface Props {
  id: number
  name: string
  diagnosisLevel: number
  communicationMethod: string
}

export function PatientCard({ id, name, diagnosisLevel, communicationMethod }: Props) {
  return (
    <Link href={`/pacientes/${id}`} className="block rounded-xl border border-slate-200 bg-white p-4 hover:border-blue-300 hover:shadow-sm transition-all">
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-700 font-semibold text-sm">
          {name[0]}
        </div>
        <div>
          <p className="font-semibold text-slate-900">{name}</p>
          <p className="text-xs text-slate-400">Nível {diagnosisLevel} · {communicationMethod}</p>
        </div>
      </div>
    </Link>
  )
}
```

- [ ] **Step 2: Write GoalProgressBar**

```typescript
// web/src/components/patients/GoalProgressBar.tsx
interface Props {
  title: string
  score: number
  domain: string
}

const COLORS: Record<string, string> = {
  communication: "bg-blue-500",
  social_skills: "bg-purple-500",
  motor: "bg-green-500",
  behavior: "bg-red-400",
  daily_living: "bg-amber-500",
  cognitive: "bg-cyan-500",
}

export function GoalProgressBar({ title, score, domain }: Props) {
  const color = COLORS[domain] ?? "bg-slate-400"
  return (
    <div>
      <div className="mb-1 flex justify-between text-xs">
        <span className="text-slate-700">{title}</span>
        <span className="font-semibold text-slate-600">{score}%</span>
      </div>
      <div className="h-1.5 w-full rounded-full bg-slate-100">
        <div className={`h-1.5 rounded-full ${color} transition-all`} style={{ width: `${score}%` }} />
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Write Patients list page**

```typescript
// web/src/app/(clinic)/pacientes/page.tsx
import { cookies } from "next/headers"
import { api } from "@/lib/api"
import { PatientCard } from "@/components/patients/PatientCard"

interface Patient { id: number; name: string; diagnosis_level: number; communication_method: string }

export default async function PatientsPage() {
  const token = (await cookies()).get("florir_token")?.value ?? ""
  const patients = await api.get<Patient[]>("/patients", token)

  return (
    <div className="p-6">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-xl font-bold text-slate-900">Pacientes</h1>
        <a href="/pacientes/novo" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">
          + Novo paciente
        </a>
      </div>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {patients.map((p) => (
          <PatientCard key={p.id} id={p.id} name={p.name}
                       diagnosisLevel={p.diagnosis_level}
                       communicationMethod={p.communication_method} />
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Write Prontuário page**

```typescript
// web/src/app/(clinic)/pacientes/[id]/page.tsx
import { cookies } from "next/headers"
import { api } from "@/lib/api"
import { GoalProgressBar } from "@/components/patients/GoalProgressBar"
import Link from "next/link"

interface Patient { id: number; name: string; birth_date: string; diagnosis_level: number; communication_method: string; diagnosis_date: string }
interface Goal { id: number; title: string; domain: string; status: string; last_score: number | null }

export default async function PatientPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const token = (await cookies()).get("florir_token")?.value ?? ""
  const [patient, goals] = await Promise.all([
    api.get<Patient>(`/patients/${id}`, token),
    api.get<Goal[]>(`/patients/${id}/goals`, token),
  ])

  const activeGoals = goals.filter((g) => g.status === "active")

  return (
    <div className="p-6">
      <div className="mb-6 flex items-center gap-4">
        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100 text-blue-700 font-bold text-lg">
          {patient.name[0]}
        </div>
        <div>
          <h1 className="text-xl font-bold text-slate-900">{patient.name}</h1>
          <p className="text-sm text-slate-500">Nível {patient.diagnosis_level} · {patient.communication_method}</p>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="rounded-xl border border-slate-200 bg-white p-4">
          <h2 className="mb-3 text-sm font-semibold text-slate-500">Informações</h2>
          <dl className="flex flex-col gap-2 text-sm">
            <div><dt className="text-slate-400">Nascimento</dt><dd className="font-medium">{new Date(patient.birth_date).toLocaleDateString("pt-BR")}</dd></div>
            {patient.diagnosis_date && <div><dt className="text-slate-400">Diagnóstico</dt><dd className="font-medium">{new Date(patient.diagnosis_date).toLocaleDateString("pt-BR")}</dd></div>}
          </dl>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-4 lg:col-span-2">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-500">Objetivos terapêuticos</h2>
            <Link href={`/pacientes/${id}/objetivos`} className="text-xs text-blue-600 hover:underline">Ver todos →</Link>
          </div>
          <div className="flex flex-col gap-3">
            {activeGoals.length === 0 ? (
              <p className="text-sm text-slate-400">Nenhum objetivo ativo.</p>
            ) : (
              activeGoals.slice(0, 4).map((g) => (
                <GoalProgressBar key={g.id} title={g.title} domain={g.domain} score={g.last_score ?? 0} />
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Verify in browser**

Open `http://localhost:3000/pacientes`. Verify list renders. Click a patient and verify prontuário loads.

- [ ] **Step 6: Commit**

```bash
git add web/
git commit -m "feat: patients list and prontuário page with goal progress bars"
```

---

### Task 16: Agenda page (calendar)

**Files:**
- Create: `web/src/app/(clinic)/agenda/page.tsx`
- Create: `web/src/components/agenda/WeekCalendar.tsx`
- Create: `web/src/components/agenda/SessionCard.tsx`

- [ ] **Step 1: Write SessionCard**

```typescript
// web/src/components/agenda/SessionCard.tsx
const STATUS_STYLES: Record<string, string> = {
  scheduled: "border-l-blue-400 bg-blue-50",
  confirmed: "border-l-green-400 bg-green-50",
  completed: "border-l-slate-300 bg-slate-50",
  cancelled: "border-l-red-300 bg-red-50 opacity-60",
  no_show: "border-l-amber-300 bg-amber-50 opacity-60",
}

interface Props {
  patientName: string
  time: string
  modality: string
  status: string
}

export function SessionCard({ patientName, time, modality, status }: Props) {
  return (
    <div className={`rounded-lg border-l-4 px-3 py-2 text-xs ${STATUS_STYLES[status] ?? "border-l-slate-300 bg-slate-50"}`}>
      <p className="font-semibold text-slate-800">{time} — {patientName}</p>
      <p className="text-slate-500 uppercase tracking-wide">{modality}</p>
    </div>
  )
}
```

- [ ] **Step 2: Write Agenda page**

```typescript
// web/src/app/(clinic)/agenda/page.tsx
import { cookies } from "next/headers"
import { api } from "@/lib/api"
import { SessionCard } from "@/components/agenda/SessionCard"

interface Session {
  id: number
  scheduled_at: string
  status: string
  modality: string
  patient_id: number
}

const DAYS = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

function startOfWeek(date: Date): Date {
  const d = new Date(date)
  d.setDate(d.getDate() - d.getDay())
  d.setHours(0, 0, 0, 0)
  return d
}

export default async function AgendaPage() {
  const token = (await cookies()).get("florir_token")?.value ?? ""
  const sessions = await api.get<Session[]>("/therapy_sessions", token)

  const now = new Date()
  const weekStart = startOfWeek(now)
  const weekDays = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(weekStart)
    d.setDate(weekStart.getDate() + i)
    return d
  })

  function sessionsForDay(day: Date) {
    return sessions.filter((s) => {
      const d = new Date(s.scheduled_at)
      return d.toDateString() === day.toDateString()
    }).sort((a, b) => new Date(a.scheduled_at).getTime() - new Date(b.scheduled_at).getTime())
  }

  return (
    <div className="p-6">
      <h1 className="mb-6 text-xl font-bold text-slate-900">Agenda</h1>
      <div className="grid grid-cols-7 gap-2">
        {weekDays.map((day, i) => {
          const daySessions = sessionsForDay(day)
          const isToday = day.toDateString() === now.toDateString()
          return (
            <div key={i} className="rounded-xl border border-slate-200 bg-white p-3 min-h-32">
              <div className={`mb-2 text-center text-xs font-semibold ${isToday ? "text-blue-600" : "text-slate-400"}`}>
                <div>{DAYS[i]}</div>
                <div className={`mt-0.5 text-lg ${isToday ? "bg-blue-600 text-white rounded-full w-7 h-7 flex items-center justify-center mx-auto" : "text-slate-700"}`}>
                  {day.getDate()}
                </div>
              </div>
              <div className="flex flex-col gap-1">
                {daySessions.map((s) => (
                  <SessionCard
                    key={s.id}
                    patientName={`Paciente #${s.patient_id}`}
                    time={new Date(s.scheduled_at).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}
                    modality={s.modality}
                    status={s.status}
                  />
                ))}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Verify in browser**

Open `http://localhost:3000/agenda`. Confirm weekly grid renders with today highlighted.

- [ ] **Step 4: Commit**

```bash
git add web/
git commit -m "feat: agenda page with weekly calendar"
```

---

### Task 17: Therapeutic Goals page with progress chart

**Files:**
- Create: `web/src/app/(clinic)/pacientes/[id]/objetivos/page.tsx`
- Create: `web/src/components/goals/GoalProgressChart.tsx`

- [ ] **Step 1: Install recharts**

```bash
cd web && npm install recharts
```

- [ ] **Step 2: Write GoalProgressChart**

```typescript
// web/src/components/goals/GoalProgressChart.tsx
"use client"
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts"

interface ProgressEntry { recorded_at: string; score: number }

export function GoalProgressChart({ data }: { data: ProgressEntry[] }) {
  const chartData = data.map((p) => ({
    date: new Date(p.recorded_at).toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" }),
    score: p.score,
  }))

  return (
    <ResponsiveContainer width="100%" height={160}>
      <LineChart data={chartData}>
        <XAxis dataKey="date" tick={{ fontSize: 10 }} />
        <YAxis domain={[0, 100]} tick={{ fontSize: 10 }} />
        <Tooltip />
        <Line type="monotone" dataKey="score" stroke="#3B82F6" strokeWidth={2} dot={{ r: 3 }} />
      </LineChart>
    </ResponsiveContainer>
  )
}
```

- [ ] **Step 3: Write Goals page**

```typescript
// web/src/app/(clinic)/pacientes/[id]/objetivos/page.tsx
import { cookies } from "next/headers"
import { api } from "@/lib/api"
import { GoalProgressChart } from "@/components/goals/GoalProgressChart"

interface Goal { id: number; title: string; domain: string; method: string; status: string; target: string }
interface Progress { id: number; recorded_at: string; score: number; notes: string }

const DOMAIN_LABELS: Record<string, string> = {
  communication: "Comunicação",
  social_skills: "Habilidades Sociais",
  behavior: "Comportamento",
  motor: "Motricidade",
  daily_living: "Vida Diária",
  cognitive: "Cognitivo",
}

const STATUS_BADGE: Record<string, string> = {
  active: "bg-green-100 text-green-700",
  achieved: "bg-blue-100 text-blue-700",
  paused: "bg-amber-100 text-amber-700",
  discontinued: "bg-slate-100 text-slate-500",
}

export default async function GoalsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const token = (await cookies()).get("florir_token")?.value ?? ""
  const goals = await api.get<Goal[]>(`/patients/${id}/goals`, token)

  const goalsWithProgress = await Promise.all(
    goals.map(async (g) => {
      const progress = await api.get<Progress[]>(`/therapeutic_goals/${g.id}/progresses`, token)
      return { ...g, progress }
    })
  )

  return (
    <div className="p-6">
      <h1 className="mb-6 text-xl font-bold text-slate-900">Plano Terapêutico</h1>
      <div className="flex flex-col gap-4">
        {goalsWithProgress.map((g) => (
          <div key={g.id} className="rounded-xl border border-slate-200 bg-white p-4">
            <div className="mb-3 flex items-start justify-between">
              <div>
                <h2 className="font-semibold text-slate-900">{g.title}</h2>
                <p className="text-xs text-slate-400">{DOMAIN_LABELS[g.domain]} · {g.method?.toUpperCase()}</p>
              </div>
              <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${STATUS_BADGE[g.status]}`}>
                {g.status}
              </span>
            </div>
            {g.target && <p className="mb-3 text-sm text-slate-600">{g.target}</p>}
            {g.progress.length > 0 ? (
              <GoalProgressChart data={g.progress} />
            ) : (
              <p className="text-sm text-slate-400 italic">Sem registros de evolução ainda.</p>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Verify in browser**

Open `/pacientes/1/objetivos`. Confirm goals render with charts when progress data exists.

- [ ] **Step 5: Commit**

```bash
git add web/
git commit -m "feat: therapeutic goals page with Recharts progress chart"
```

---

### Task 18: Family portal

**Files:**
- Create: `web/src/app/familia/[token]/layout.tsx`
- Create: `web/src/app/familia/[token]/progresso/page.tsx`
- Create: `web/src/app/familia/[token]/sessoes/page.tsx`
- Create: `web/src/app/familia/[token]/mensagens/page.tsx`

- [ ] **Step 1: Write family layout**

```typescript
// web/src/app/familia/[token]/layout.tsx
import Link from "next/link"

const NAV = [
  { href: "progresso", label: "Progresso" },
  { href: "sessoes", label: "Sessões" },
  { href: "mensagens", label: "Mensagens" },
]

export default async function FamiliaLayout({
  children,
  params,
}: {
  children: React.ReactNode
  params: Promise<{ token: string }>
}) {
  const { token } = await params
  return (
    <div className="min-h-screen bg-blue-50">
      <header className="bg-white border-b border-slate-200 px-4 py-3 flex items-center justify-between">
        <span className="font-bold text-blue-700">Florir</span>
        <nav className="flex gap-4">
          {NAV.map((n) => (
            <Link key={n.href} href={`/familia/${token}/${n.href}`}
                  className="text-sm text-slate-600 hover:text-blue-600 transition-colors">
              {n.label}
            </Link>
          ))}
        </nav>
      </header>
      <main className="mx-auto max-w-2xl px-4 py-6">{children}</main>
    </div>
  )
}
```

- [ ] **Step 2: Write Progresso page**

```typescript
// web/src/app/familia/[token]/progresso/page.tsx
import { api } from "@/lib/api"
import { GoalProgressBar } from "@/components/patients/GoalProgressBar"

interface DashboardData {
  patient: { name: string; diagnosis_level: number }
  goals: { id: number; title: string; domain: string; last_score: number | null }[]
  next_session: { scheduled_at: string; modality: string } | null
}

export default async function FamiliaProgressoPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = await params
  const data = await api.get<DashboardData>(`/family/${token}/dashboard`)

  return (
    <div className="flex flex-col gap-4">
      <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-200">
        <h1 className="text-lg font-bold text-slate-900">Olá! 👋</h1>
        <p className="text-sm text-slate-500">Acompanhando: <strong>{data.patient.name}</strong> · Nível {data.patient.diagnosis_level}</p>
        {data.next_session && (
          <div className="mt-3 rounded-lg bg-blue-50 px-3 py-2 text-xs text-blue-700 border border-blue-100">
            Próxima sessão: {new Date(data.next_session.scheduled_at).toLocaleDateString("pt-BR")} · {data.next_session.modality.toUpperCase()}
          </div>
        )}
      </div>

      <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-200">
        <h2 className="mb-4 text-sm font-semibold text-slate-600">Objetivos em andamento</h2>
        <div className="flex flex-col gap-3">
          {data.goals.map((g) => (
            <GoalProgressBar key={g.id} title={g.title} domain={g.domain} score={g.last_score ?? 0} />
          ))}
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Write Sessoes page**

```typescript
// web/src/app/familia/[token]/sessoes/page.tsx
import { api } from "@/lib/api"

interface Session { id: number; scheduled_at: string; modality: string; status: string; duration_minutes: number }

export default async function FamiliaSessoesPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = await params
  const sessions = await api.get<Session[]>(`/family/${token}/sessions`)

  return (
    <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-200">
      <h1 className="mb-4 text-lg font-bold text-slate-900">Próximas sessões</h1>
      {sessions.length === 0 ? (
        <p className="text-sm text-slate-400">Nenhuma sessão agendada.</p>
      ) : (
        <div className="flex flex-col gap-3">
          {sessions.map((s) => (
            <div key={s.id} className="flex items-center gap-4 rounded-lg border border-slate-100 p-3">
              <div className="text-center">
                <p className="text-lg font-bold text-blue-600">{new Date(s.scheduled_at).getDate()}</p>
                <p className="text-xs text-slate-400">{new Date(s.scheduled_at).toLocaleDateString("pt-BR", { month: "short" })}</p>
              </div>
              <div>
                <p className="font-medium text-slate-800">{s.modality.toUpperCase()} · {s.duration_minutes} min</p>
                <p className="text-xs text-slate-400">{new Date(s.scheduled_at).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}</p>
              </div>
              <span className="ml-auto rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-700">{s.status}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 4: Write Mensagens page**

```typescript
// web/src/app/familia/[token]/mensagens/page.tsx
import { api } from "@/lib/api"

interface Message { id: number; body: string; sender_id: number; created_at: string; read_at: string | null }

export default async function FamiliaMensagensPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = await params
  const messages = await api.get<Message[]>(`/family/${token}/messages`)

  return (
    <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-200">
      <h1 className="mb-4 text-lg font-bold text-slate-900">Mensagens</h1>
      <div className="flex flex-col gap-3">
        {messages.map((m) => (
          <div key={m.id} className="rounded-lg bg-slate-50 p-3 border border-slate-100">
            <p className="text-sm text-slate-800">{m.body}</p>
            <p className="mt-1 text-xs text-slate-400">
              {new Date(m.created_at).toLocaleDateString("pt-BR", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" })}
              {!m.read_at && <span className="ml-2 rounded-full bg-blue-100 px-1.5 py-0.5 text-blue-600">Nova</span>}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Verify in browser**

Open `http://localhost:3000/familia/[access_token]/progresso`. Confirm family portal renders.

- [ ] **Step 6: Commit**

```bash
git add web/
git commit -m "feat: family portal with progress, sessions, and messages"
```

---

### Task 19: Final — lint, build, and CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Run Rails full test suite**

```bash
cd api && bin/rails test
```

Expected: all tests PASS, 0 failures.

- [ ] **Step 2: Run Brakeman**

```bash
cd api && bundle exec brakeman --no-pager
```

Expected: 0 high-severity warnings.

- [ ] **Step 3: Run RuboCop**

```bash
cd api && bundle exec rubocop
```

Expected: no offenses (or only Style/cops you've chosen to ignore).

- [ ] **Step 4: Run Next.js type check and build**

```bash
cd web && npx tsc --noEmit && npm run build
```

Expected: 0 TypeScript errors, build succeeds.

- [ ] **Step 5: Write GitHub Actions CI**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  rails:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: api
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true
      - name: Setup DB
        run: bin/rails db:create db:migrate
        env:
          RAILS_ENV: test
      - name: Run tests
        run: bin/rails test
      - name: Brakeman
        run: bundle exec brakeman --no-pager

  nextjs:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: web
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
          cache-dependency-path: web/package-lock.json
      - run: npm ci
      - run: npx tsc --noEmit
      - run: npm run build
        env:
          NEXT_PUBLIC_API_URL: http://localhost:4000
          NEXT_PUBLIC_APP_URL: http://localhost:3000
```

- [ ] **Step 6: Final commit**

```bash
git add .github/ api/ web/
git commit -m "chore: CI pipeline with Rails tests + Next.js build"
```

---

## Summary

| Task | What it builds |
|------|---------------|
| 1 | Rails bootstrap with rails-harness + Turso |
| 2 | Clinic + User models, multi-tenancy |
| 3 | Patient, TherapySession, TherapeuticGoal, GoalProgress |
| 4 | FamilyAccess (magic link) + Message |
| 5 | JWT auth — login, register, tenant scoping |
| 6 | Patients API with tenant isolation |
| 7 | TherapySessions API |
| 8 | TherapeuticGoals + GoalProgresses API |
| 9 | Family portal API + Messages |
| 10 | Solid Queue jobs — magic link + session reminders |
| 11 | CORS, Brakeman, RuboCop |
| 12 | Next.js bootstrap, API client, auth helpers |
| 13 | Login page |
| 14 | Dashboard layout with sidebar |
| 15 | Patients list + prontuário |
| 16 | Agenda — weekly calendar |
| 17 | Goals page with Recharts progress chart |
| 18 | Family portal — 4 pages |
| 19 | Full CI pipeline |
