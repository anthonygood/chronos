require 'spec_helper'

describe "Timeline" do
  before do
    allow(Chronos::User).to receive(:find).with('bob_123'){ user('bob_123') }
    allow(Chronos::User).to receive(:find).with('jane_123'){ user('jane_123') }
  end

  let(:bob) { 'bob_123'}  
  let(:jane) { 'jane_123' }

  def user(user_id)
    {
      "first_name" => "firstname_#{user_id}",
      "last_name" => "lastname_#{user_id}",
      "profile_image_url" => "http://example.com/foo.png"
    }
  end
  
  def expected_item(time, user_id)
    {
      key: "activity.topic.attempted",
      created_ts: time,
      trackable: {
        type: "Topic", 
        name: "Balls",
        course_id: "1234",
        bundle_id: "5678"
      },
      owner: {
        first_name: "firstname_#{user_id}",
        last_name: "lastname_#{user_id}",
        profile_image_url: "http://example.com/foo.png"
      }
    }
  end

  def log(opts = {})
    memo = {
      key: "activity.topic.attempted",
      user_id: '1234',
      type: "Topic", 
      name: "Balls",
      course_id: "1234",
      bundle_id: "5678",
      trackable_id: '123',
      student_group_id: '123',
      created_ts: Time.now.to_i,
      data: {
        score: 50,
        attempt: 1
      }
    }.merge!(opts)

    Chronos::Timeline.log(memo)
  end

  before :each do
    Redis.new.flushdb
  end

  it "has activities" do
    log(created_ts: 4000, user_id: jane)
    log(created_ts: 3000, user_id: bob)

    expected = {
      grouped_activities: [
        expected_item(4000, jane),
        expected_item(3000, bob)
      ]
    }

    expect(Chronos::Timeline.fetch('123')).to eql(expected)
  end
  it "has nested activities" do
    log(created_ts: 1000, user_id: jane)
    log(created_ts: 2000, user_id: bob)
    log(created_ts: 3000, user_id: bob)
    log(created_ts: 4000, user_id: jane)

    expected = {
      grouped_activities: [
        expected_item(4000, jane),
        expected_item(3000, bob).merge!(
          related: [
            expected_item(2000, bob)
          ]
        ),
        expected_item(1000, jane),
      ]
    } 
    
    expect(Chronos::Timeline.fetch('123')).to eql(expected)
  end

end