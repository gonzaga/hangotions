require 'json'
path_to_archive = ARGV[0] || "/Users/tatianapotetinova/Downloads/devochka.v.kube@gmail.com-20131208T195813Z-chat/Hangouts/Hangouts.json"

archive = JSON.parse(File.read(path_to_archive))
emoji_regex = Regexp.new(/[\xF0\x9F\x98\x81-\xF0\x9F\x99\x8F]/)

conversations = archive["conversation_state"]
conversations_stats = {}

conversations.each do |conversation|
  conversation_id = conversation["conversation_id"]["id"]
  conversations_stats[conversation_id] = collect_participant_data(conversation)
  conversation["conversation_state"]["event"].each do |event|
    sender_id = event["sender_id"]["gaia_id"]
    sender_stat = conversations_stats[conversation_id][sender_id] || {}
    sender_stat["emojis"] ||= []
    if event["chat_message"]
      if event["chat_message"]["message_content"]["segment"]
        event["chat_message"]["message_content"]["segment"].each do |message|
          if message["type"] == "TEXT"
            sender_stat["emojis"] += message["text"].scan(emoji_regex)
          end
        end
      else
        unless event["chat_message"]["message_content"]["attachment"]
          puts event["chat_message"]["message_content"] unless event["chat_message"]["message_content"]["attachment"]
        end
      end
    end
  end
end
stats_by_name = {}

conversations_stats.each do |conversation_id, stats|
  puts conversation_id
  stats.each do |id, stat|
    puts stat["name"]
    stats_by_name[stat["name"]] ||= {}
    stats_by_name[stat["name"]]["emojis"] ||= []
    stats_by_name[stat["name"]]["emojis"] += stat["emojis"]
    puts count_and_sort(stat["emojis"])[0..9]
  end
end

stats_by_name.each do |name, stat|
  puts name
  puts count_and_sort(stat["emojis"])[0..9]
end

def count_and_sort(emoji_array)
  counts = Hash.new(0)
  emoji_array.each { |emoji| counts[emoji] += 1 }
  counts.sort_by{|k,v| v}.reverse
end

def collect_participant_data(conversation)
  participant_data = {}
  conversation["conversation_state"]["conversation"]["participant_data"].each do |data|
    participant_data[data["id"]["gaia_id"]] = { "name" => data["fallback_name"] }
  end
  participant_data
end