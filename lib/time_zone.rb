module TimeZone
  def time_zones_with_time(hour)
    ActiveSupport::TimeZone.zones_with_time_diff_to_utc(hour - Time.zone.now.hour + Time.zone.utc_offset / 3600)
  end
  
  def time_zone_from_ip(ip)
    location = open("http://api.hostip.info/get_html.php?ip=#{ip}&position=true")
    if location.string =~ /Latitude: (.+?)\nLongitude: (.+?)\n/
      timezone = Geonames::WebService.timezone($1, $2)
      ActiveSupport::TimeZone::MAPPING.index(timezone.timezone_id) unless timezone.nil?
    end
  end
end
