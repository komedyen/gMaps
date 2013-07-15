require 'nokogiri'
require 'geocoder'
require 'open-uri'
require 'mechanize'

class Location < ActiveRecord::Base
  attr_accessible :address, :latitude, :longitude
  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude
  after_validation :geocode, :reverse_geocode

  def air
    @ports = []
    loc = Geocoder.search(address).first
    prep = 'near+' << loc.address_components[4]['long_name'] << '+' << loc.country
    agent = Mechanize.new
    page = agent.get('https://maps.google.com/maps?q=airport+' << prep)
    doc = page.parser
    doc.css('span.pp-place-title').each do |link|
      addr = link.content
      airport = Geocoder.search(addr)
      @ports << airport
    end
    @ports
  end

  def bus
    @stops = []
    agent = Mechanize.new
    page = agent.get('https://maps.google.com/maps?q=otobus+duraklari+near+' << address.tr(' ', '+'))
    doc = page.parser
    doc.css('span.pp-headline-item.pp-headline-address').each do |link|
      addr = link.content
      stop = Geocoder.search(addr)
      @stops << stop
    end
    @stops
  end

  def restaurant
    @places = []
    agent = Mechanize.new
    page = agent.get('https://maps.google.com/maps?q=restaurants+near+' << address.tr(' ', '+'))
    doc = page.parser
    begin
      doc.css('span.pp-headline-item.pp-headline-address').each do |link|
        addr = link.content
        place = Geocoder.search(addr)
        puts addr
        @places << place
      end
    end while agent.click(page.search(:css => 'td.b'))
    @places
  end

  def hosp
    agent = Mechanize.new
    page = agent.get('https://maps.google.com/maps?q=hospital+near+' << address.tr(' ', '+'))
    doc = page.parser
    link = doc.css('span.pp-headline-item.pp-headline-address').first
    addr = link.content
    hospital = Geocoder.search(addr).first
  end

end
