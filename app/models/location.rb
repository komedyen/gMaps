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
    loc = Geocoder.search(address).first
    prep = 'https://maps.google.com/maps?q=airports+near+' << loc.city << '+' << loc.country
    crawl(prep, "airport")
  end

  def bus
    prep = 'https://maps.google.com/maps?q=bus+stations+near+' << address.tr(' ', '+')
    crawl(prep, "bus_station")
  end

  def restaurant
    prep = 'https://maps.google.com/maps?q=restaurants+near+' << address.tr(' ', '+')
    crawl(prep, "point_of_interest")
  end

  def hosp
    prep = 'https://maps.google.com/maps?q=Hospital+' << address.tr(' ', '+')
    crawl(prep, "point_of_interest")
  end

  def crawl(url, key)
    @uno = []
    a = Mechanize.new
    page = a.get(url)
    gsForm = page.forms[0]
    gsForm.encoding = 'utf-8'
    gForm = gsForm.submit
    gDoc = gForm.parser
    data = gDoc.css('script').text
    data = data.to_s[64..-4][0..-14]
    parsed = eval(data)[:overlays][:markers]
    parsed.each do |node|
      prep = node[:latlng][:lat].to_s << ','
      prep << node[:latlng][:lng].to_s
      @uno << validate(prep, key)
    end
    @uno.compact
  end

  def validate(data, key)
    coded = Geocoder.search(data)
    if key == "airport" || key == "bus_station"
      coded.each do |d|
        if d.types.include?(key) then
          @result = d
        end
      end
    else
        @result = coded.first
    end
    @result
  end

end
