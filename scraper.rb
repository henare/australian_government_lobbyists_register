#!/usr/bin/env ruby

require 'mechanize'
require 'csv'

agent = Mechanize.new
base_url = 'https://lobbyists.pmc.gov.au/'
table = agent.get("#{base_url}who_register.cfm").at(:table)

agencies = table.at(:tbody).search(:tr).map do |row|
  last_updated = row.search(:td)[4].inner_text.strip.empty? ? '' : Date.parse(row.search(:td)[4].inner_text)

  {url: base_url + row.search(:td)[1].at(:a).attr(:href),
   business_entity_name: row.search(:td)[1].inner_text,
   trading_name: row.search(:td)[2].inner_text,
   abn: row.search(:td)[3].inner_text,
   details_last_updated: last_updated}
end

agencies_csv = CSV.new(File.open('agencies.csv', 'w'), write_headers: true, headers: ['id', 'url', 'business_entity_name', 'trading_name', 'abn', 'details_last_updated'])
owners_csv = CSV.new(File.open('owners.csv', 'w'), write_headers: true, headers: ['agency_id', 'agency_business_entity_name', 'owner_name'])
lobbyists_csv = CSV.new(File.open('lobbyists.csv', 'w'), write_headers: true, headers: ['agency_id', 'agency_business_entity_name', 'lobbyist_name', 'position', 'former_government_representative', 'cessation_date'])
clients_csv = CSV.new(File.open('clients.csv', 'w'), write_headers: true, headers: ['agency_id', 'agency_business_entity_name', 'client_name'])

agencies.each do |agency|
  agency_id = agency[:url].match('id=(.*)')[1]

  agency_page = agent.get agency[:url]

  agencies_csv << [
    agency_id,
    agency[:url],
    agency[:business_entity_name],
    agency[:trading_name],
    agency[:abn],
    agency[:details_last_updated],
  ]

  # Save owners
  agency_page.at('#profile').search(:ul).last.search(:li).each do |li|
     owners_csv << [agency_id, agency[:business_entity_name], li.inner_text]
  end

  # Save lobbyists
  if agency_page.at('#lobbyistDetails')
    agency_page.at('#lobbyistDetails').at(:tbody).search(:tr).each do |row|
      lobbyists_csv << [agency_id,
                        agency[:business_entity_name],
                        row.search(:td)[1].inner_text,
                        row.search(:td)[2].inner_text,
                        row.search(:td)[3].inner_text,
                        row.search(:td)[4].inner_text.strip]
    end
  end

  # Save clients
  if agency_page.at('#clientDetails')
    agency_page.at('#clientDetails').at(:tbody).search(:tr).each do |row|
      clients_csv << [agency_id, agency[:business_entity_name], row.search(:td)[1].inner_text]
    end
  end
end
