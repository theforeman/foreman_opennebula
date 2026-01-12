FactoryBot.define do
  trait :opennebula do
    provider { 'OpenNebula' }
    url { 'http://one.example.com:2633/RPC2' }
    user { 'oneadmin' }
    password { 'secret' }
    after(:build) { |cr| cr.stubs(:connect) }
  end
end
