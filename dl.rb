#!/usr/bin/env ruby

require 'logger'
require 'mechanize'
require 'prawn'
require 'json'
require "open-uri"

cid = ARGV[0]

exit unless cid

logger = Logger.new "log/#{ cid }.log"
agent = Mechanize.new
agent.log = logger
agent.user_agent_alias = 'Mac Safari'
tmp_dir = 'tmp'

agent.get "http://archives.nyphil.org/index.php/artifact/#{ cid }" do |page|

  page.search('#partsList').search('tr').each do |row|
    part_name = row.css('td')[0]
    link = row.css('td a[href$=fullview]')
    next unless part_name && link

    part_name = part_name.content
    link = link.attr('href').value

    json_url = link.sub %r{artifact/([a-z0-9\-]+)/fullview}, 'booksearch/\1'

    agent.get json_url do |json_res|
      json = JSON.parse json_res.body
      logger.info "Start creating #{ part_name }.pdf"
      Prawn::Document.generate("output/#{ part_name }.pdf", :page_size => "A4", :page_layout => :portrait) do
        json.each_with_index do |obj, index|
          uid = obj['3000']
          jpeg_url = "http://archives.nyphil.org/alfresco/gd/d/workspace/SpacesStore/#{uid}/test.jpg"
          jpeg_path = "#{tmp_dir}/#{uid}.jpg"
          logger.info "Downloading image #{index+1} of #{json.count}"
          unless File.exist? jpeg_path
            File.open(jpeg_path, 'wb') do |fo|
              fo.write open(jpeg_url).read
            end
          end
          start_new_page if index > 0
          s = 2.7
          image jpeg_path, position: :center, vposition: :center, fit: [210 * s, 297 * s]
        end
      end
    end

  end

end

