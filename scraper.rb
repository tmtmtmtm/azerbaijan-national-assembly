#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('#mod_senter_text select').first.css('option/@value').each do |opt|
    scrape_mp(opt.text)
  end
end

def scrape_mp(id)
  return if id.to_s.empty?
  url = 'http://meclis.gov.az/?/az/deputat/%s' % id
  noko = noko_for(url)

  box = noko.css('#content')
  if constituency = box.css('#mod_senter_text strong').text.match(/(\d+)\s+(.*)/)
    area_id, area = constituency.captures
  else
    area_id = ''
    area = ''
  end

  data = {
    id:      id,
    name:    box.css('#cit h1').text.tidy,
    image:   box.css('#mod_senter_text img/@src').text,
    area:    area.tidy,
    area_id: area_id,
    party:   box.css('#mod_senter_text').xpath('.//p[contains(.,"mənsubiyyəti")]').text.to_s.split(/:/).last.to_s.tidy,
    term:    '5',
    source:  url,
  }
  data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
  data[:party] = 'Independent' if data[:party].to_s == 'bitərəf'
  # puts data
  ScraperWiki.save_sqlite(%i[id term], data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://meclis.gov.az/?/az/deputat/')
