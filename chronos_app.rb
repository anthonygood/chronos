require 'digest/sha1'
require 'redis'
require 'json'

module Chronos
  class User
    def self.find(id)
    end
  end
  class Store
    @@redis = ::Redis.new

    def self.db
      @@redis
    end
  end

  class Timeline

    class << self
      def log(data)
        # key = "student_group:#{data[:student_group_id]}:users:#{data[:user_id]}"
        # member = Digest::SHA1.hexdigest "#{data[:user_id]}#{data[:topic_id]}#{data[:created_ts]}"

        # puts "log . . . ."
        # puts slist_key(data)
        # puts student_group_list_key(data)

        Store.db.zadd slist_key(data), data[:time], member(data)
        Store.db.hset "users:#{data[:user_id]}:timeline_activities", member(data), data.to_json
        Store.db.zadd student_group_list_key(data), data[:time], data[:user_id]
      end

      def fetch(id)
        # { grouped_activities: [
        #     key: "activity.topic.attempted",
        #     created_ts: Time.now,
        #     trackable: {
        #       type: "Topic", 
        #       name: "Balls",
        #       course_id: "1234",
        #       bundle_id: "5678"
        #     },
        #     owner: {
        #       first_name: "Bob",
        #       last_name: "Nakano",
        #       profile_image_url: "http://example.com/foo.png"
        #     }
        #   ]
        # }
        items      = Store.db.zrange student_group_list_key(student_group_id: id), 0, 20
        
        puts items.class
        memo = []
        items.each do |user_id|
          hash_key = Store.db.zrange slist_key(student_group_id: id, user_id: user_id), 0, 1
          data = Store.db.hget "users:#{user_id}:timeline_activities", hash_key.first
          
          user = Chronos::User.find(user_id)
          data = JSON.parse(data)

          item = {
            key: data["key"],
            created_ts: data["created_ts"],
            trackable: {
              type: data["type"],
              name: data["name"],
              course_id: data["course_id"],
              bundle_id: data["bundle_id"]
            },

            owner: {
              first_name: user['first_name'],
              last_name: user['last_name'],
              profile_image_url: user['profile_image_url']
            }
          }

          memo.unshift item
        end
        

        {
          grouped_activities: memo
        }
        # puts "ITEMS! >> ", id
        # puts items
      end

      private

      def slist_key(data)
        "student_group:#{data[:student_group_id]}:users:#{data[:user_id]}:timeline"
      end

      def student_group_list_key(data)
        "student_group:#{data[:student_group_id]}:timeline"
      end

      def member(data)
        Digest::SHA1.hexdigest "#{data[:user_id]}#{data[:key]}#{data[:created_ts]}"
      end
    end

  end
end

require "sinatra"

get "/hi" do
  "Hello again"
end
