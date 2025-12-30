# frozen_string_literal: true

#written by an unpickable december

require 'net/http'
require 'json'

#this is a module to check the status of arch linux services, in the face of many ddos attacks in 2025
module ArchStatus
  extend Discordrb::Commands::CommandContainer

  #api endpoint provided by dotle
  API_URL = 'https://status.archlinux.org/api/getMonitorList/vmM5ruWEAB'

  #we identify ourselves
  USER_AGENT = 'qbot (Arch Linux Community bot; +https://github.com/arch-community/qbot)'

  command :archstatus, {
    help_available: true,
    description: 'Checks live (enough) status of Arch Linux services (AUR, wiki, &c)',
    usage: '.archstatus'
  } do |event|
    data = fetch_status_data
    next event.respond "nope. could not reach the API" unless data

    monitors = data.dig('psp', 'monitors')
    next event.respond "caution: no monitor data found in API response" unless monitors

    #trying to use embed helper
    embed do |m|
      m.title = 'Arch Service Status'
      m.color = 0x1793d1
      m.timestamp = Time.now
      m.footer = { text: 'status.archlinux.org' }

      monitors.each do |mon|
        status_indicator = case mon['statusClass']
                           when 'success' then '🟢 up'
                           when 'danger'  then '🔴 down'
                           when 'warning' then '🟡 wonky'
                           else '⚪ unown'
                           end

        m.add_field(name: mon['name'], value: status_indicator, inline: true)
      end
    end
  end 

  def self.fetch_status_data
    uri = URI(API_URL)

    #we're using Net::HTTP directly, as it's already required by qbot
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = USER_AGENT

    begin
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        response = http.request(request)
        JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
      end
    rescue StandardError => e
      # ref to qbot logger QBot.log 
      QBot.log.error "ArchStatus: Failed to fetch API: #{e.message}"
      nil
    end
  end
end
