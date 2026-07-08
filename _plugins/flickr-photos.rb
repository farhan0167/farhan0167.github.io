require 'httparty'
require 'jekyll'
require 'nokogiri'

# Fetches the Flickr photostream RSS configured under `flickr_feed` in
# _config.yml and exposes the photos as site.data['flickr_photos'],
# rendered by _pages/photos.md.
module FlickrPhotos
  MEDIA_NS = { 'media' => 'http://search.yahoo.com/mrss/' }.freeze

  class FlickrPhotosGenerator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      cfg = site.config['flickr_feed']
      return if cfg.nil? || cfg['rss_url'].to_s.empty?

      puts "Fetching Flickr photos from #{cfg['rss_url']}:"
      begin
        xml = HTTParty.get(cfg['rss_url']).body
        doc = Nokogiri::XML(xml)
      rescue StandardError => e
        puts "Error fetching Flickr feed - #{e.message}"
        return
      end

      photos = doc.xpath('//item').filter_map do |item|
        img = item.at_xpath('.//media:content', MEDIA_NS)&.attr('url')
        # fall back to the first image in the item description
        img ||= Nokogiri::HTML(item.at_xpath('description')&.text.to_s).at('img')&.attr('src')
        next if img.nil?

        {
          'title' => item.at_xpath('title')&.text.to_s.strip,
          'page_url' => item.at_xpath('link')&.text,
          'img_url' => img,
          'date' => item.at_xpath('pubDate')&.text
        }
      end

      puts "...found #{photos.size} photos"
      site.data['flickr_photos'] = photos
    end
  end
end
