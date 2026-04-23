# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_23_173848) do
  create_table "clinics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "plan"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_clinics_on_slug", unique: true
  end

  create_table "goal_progresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "goal_id", null: false
    t.text "notes"
    t.datetime "recorded_at", null: false
    t.integer "score", null: false
    t.integer "session_id", null: false
    t.integer "therapist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["goal_id"], name: "index_goal_progresses_on_goal_id"
    t.index ["session_id"], name: "index_goal_progresses_on_session_id"
    t.index ["therapist_id"], name: "index_goal_progresses_on_therapist_id"
  end

  create_table "patients", force: :cascade do |t|
    t.date "birth_date"
    t.integer "clinic_id", null: false
    t.string "communication_method"
    t.datetime "created_at", null: false
    t.date "diagnosis_date"
    t.integer "diagnosis_level"
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["clinic_id"], name: "index_patients_on_clinic_id"
  end

  create_table "therapeutic_goals", force: :cascade do |t|
    t.date "achieved_at"
    t.integer "clinic_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "domain", null: false
    t.string "method"
    t.integer "patient_id", null: false
    t.date "started_at"
    t.string "status", null: false
    t.text "target"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["clinic_id"], name: "index_therapeutic_goals_on_clinic_id"
    t.index ["patient_id"], name: "index_therapeutic_goals_on_patient_id"
  end

  create_table "therapy_sessions", force: :cascade do |t|
    t.integer "clinic_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration_minutes"
    t.string "modality"
    t.integer "patient_id", null: false
    t.datetime "scheduled_at", null: false
    t.text "session_notes"
    t.string "status", null: false
    t.integer "therapist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["clinic_id"], name: "index_therapy_sessions_on_clinic_id"
    t.index ["patient_id"], name: "index_therapy_sessions_on_patient_id"
    t.index ["therapist_id"], name: "index_therapy_sessions_on_therapist_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "clinic_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["clinic_id", "email"], name: "index_users_on_clinic_id_and_email", unique: true
    t.index ["clinic_id"], name: "index_users_on_clinic_id"
  end

  add_foreign_key "goal_progresses", "therapeutic_goals", column: "goal_id"
  add_foreign_key "goal_progresses", "therapy_sessions", column: "session_id"
  add_foreign_key "goal_progresses", "users", column: "therapist_id"
  add_foreign_key "patients", "clinics"
  add_foreign_key "therapeutic_goals", "clinics"
  add_foreign_key "therapeutic_goals", "patients"
  add_foreign_key "therapy_sessions", "clinics"
  add_foreign_key "therapy_sessions", "patients"
  add_foreign_key "therapy_sessions", "users", column: "therapist_id"
  add_foreign_key "users", "clinics"
end
