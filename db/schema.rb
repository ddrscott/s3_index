# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161109000001) do

  create_table "s3_index", force: :cascade do |t|
    t.integer  "owner_id"
    t.string   "file_name"
    t.string   "content_type"
    t.string   "md5sum"
    t.integer  "size"
    t.string   "origin_url"
    t.string   "s3_url"
    t.string   "s3_bucket"
    t.string   "s3_env"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "s3_index", ["content_type"], name: "index_s3_index_on_content_type"
  add_index "s3_index", ["file_name"], name: "index_s3_index_on_file_name"
  add_index "s3_index", ["md5sum"], name: "index_s3_index_on_md5sum"
  add_index "s3_index", ["origin_url"], name: "index_s3_index_on_origin_url"
  add_index "s3_index", ["owner_id"], name: "index_s3_index_on_owner_id"
  add_index "s3_index", ["s3_url"], name: "index_s3_index_on_s3_url"

end
