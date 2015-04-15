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

        Store.db.zadd slist_key(data), data[:created_ts], member(data)
        Store.db.hset "users:#{data[:user_id]}:timeline_activities", member(data), data.to_json
        Store.db.zadd student_group_list_key(data), data[:created_ts], data[:user_id]
      end

      def fetch(id)
    
        items = Store.db.zrevrange student_group_list_key(student_group_id: id), 0, 20, with_scores: true
        # p items, "items"


        memo = []
        items.each_with_index do |item, index|
          next_item = items[index + 1]
          
          key = slist_key(student_group_id: id, user_id: item[0])
          
          if next_item
            from = next_item[1].to_i
          else
             from = item[1] 
          end

          to = item[1].to_i

          students_items = Store.db.zrangebyscore  key, from, to
          all = Store.db.zrange key, 0, -1, with_scores: true
          p [from, to, item[0]]
          p "all: ", all
          p students_items, item[0]

          students_items.each do |student_item|            
            hash_key = student_item
            # Store.db.zrange slist_key(student_group_id: id, user_id: item[0]), 0, 1
            
            data = Store.db.hget "users:#{item[0]}:timeline_activities", hash_key
            
            item = data_for_activity( JSON.parse(data) )
            memo.push item
          end
        end
        
        puts memo

        {
          grouped_activities: memo
        }
        # puts "ITEMS! >> ", id
        # puts items
      end

      private
      def data_for_activity(data)
        user = Chronos::User.find(data['user_id'])

        {
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
      end

      def slist_key(data)
        "student_group:#{data[:student_group_id]}:users:#{data[:user_id]}:timeline"
      end

      def student_group_list_key(data)
        "student_group:#{data[:student_group_id]}:timeline"
      end

      def member(data)
        Digest::SHA1.hexdigest "#{data[:user_id]}#{data[:key]}#{data[:created_ts]}"
      end

      def group_consecutive(documents)
        documents.inject([]) do |memo, document|
          last = memo.last

          if last && last[:primary].owner_id == document.owner_id
            memo.last[:related] << document
          else
            memo << { primary: document, related: [] }
          end
          memo
        end
      end

    end

  end
end

require "sinatra"

get "/hi" do
  "Hello again"
end
